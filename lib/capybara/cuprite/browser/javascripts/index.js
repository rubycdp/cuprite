class InvalidSelector extends Error {}
class TimedOutPromise extends Error {}
class MouseEventFailed extends Error {}

const EVENTS = {
  FOCUS: ["blur", "focus", "focusin", "focusout"],
  MOUSE: ["click", "dblclick", "mousedown", "mouseenter", "mouseleave",
          "mousemove", "mouseover", "mouseout", "mouseup", "contextmenu"],
  FORM: ["submit"]
}

class Cuprite {
  find(method, selector, within = document) {
    try {
      let results = [];

      if (method == "xpath") {
        let xpath = document.evaluate(selector, within, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
        for (let i = 0; i < xpath.snapshotLength; i++) {
          results.push(xpath.snapshotItem(i));
        }
      } else {
        results = within.querySelectorAll(selector);
      }

      return results;
    } catch (error) {
      // DOMException.INVALID_EXPRESSION_ERR is undefined, using pure code
      if (error.code == DOMException.SYNTAX_ERR || error.code == 51) {
        throw new InvalidSelector;
      } else {
        throw error;
      }
    }
  }

  visibleText(node) {
    if (this.isVisible(node)) {
      if (node.nodeName == "TEXTAREA") {
        return node.textContent;
      } else {
        if (node instanceof SVGElement) {
          return node.textContent;
        } else {
          return node.innerText;
        }
      }
    }
  }

  isVisible(node) {
    let mapName, style;
    // if node is area, check visibility of relevant image
    if (node.tagName === "AREA") {
      mapName = document.evaluate("./ancestor::map/@name", node, null, XPathResult.STRING_TYPE, null).stringValue;
      node = document.querySelector(`img[usemap="#${mapName}"]`);
      if (node == null) {
        return false;
      }
    }

    while (node) {
      style = window.getComputedStyle(node);
      if (style.display === "none" || style.visibility === "hidden" || parseFloat(style.opacity) === 0) {
        return false;
      }
      node = node.parentElement;
    }

    return true;
  }


  isDisabled(node) {
    let xpath = "parent::optgroup[@disabled] | \
                 ancestor::select[@disabled] | \
                 parent::fieldset[@disabled] | \
                 ancestor::*[not(self::legend) or preceding-sibling::legend][parent::fieldset[@disabled]]";

    return node.disabled || document.evaluate(xpath, node, null, XPathResult.BOOLEAN_TYPE, null).booleanValue;
  }

  path(node) {
    let nodes = [node];
    let parent = node.parentNode;
    while (parent !== document) {
      nodes.unshift(parent);
      parent = parent.parentNode;
    }

    let selectors = nodes.map(node => {
      let prevSiblings = [];
      let xpath = document.evaluate(`./preceding-sibling::${node.tagName}`, node, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);

      for (let i = 0; i < xpath.snapshotLength; i++) {
        prevSiblings.push(xpath.snapshotItem(i));
      }

      return `${node.tagName}[${(prevSiblings.length + 1)}]`;
    });

    return `//${selectors.join("/")}`;
  }

  scrollIntoViewport(node) {
    let areaImage = this._getAreaImage(node);

    if (areaImage) {
      return this.scrollIntoViewport(areaImage);
    } else {
      node.scrollIntoViewIfNeeded();

      if (!this._isInViewport(node)) {
        node.scrollIntoView({block: "center", inline: "center", behavior: "instant"});
        return this._isInViewport(node);
      }

      return true;
    }
  }

  mouseEventTest(node, name, x, y) {
    let frameOffset = this._frameOffset();
    x -= frameOffset.left;
    y -= frameOffset.top;

    let element = document.elementFromPoint(x, y);

    let el = element;
    while (el) {
      if (el == node) {
        return true;
      } else {
        el = el.parentNode;
      }
    }

    let selector = element && this._getSelector(element) || "none";
    throw new MouseEventFailed([name, selector, x, y].join(", "));
  }

  _getAreaImage(node) {
    if ("area" == node.tagName.toLowerCase()) {
      let map = node.parentNode;
      if (map.tagName.toLowerCase() != "map") {
        throw new Error("the area is not within a map");
      }

      let mapName = map.getAttribute("name");
      if (typeof mapName === "undefined" || mapName === null) {
        throw new Error("area's parent map must have a name");
      }

      mapName = `#${mapName.toLowerCase()}`;
      let imageNode = this.find("css", `img[usemap='${mapName}']`)[0];
      if (typeof imageNode === "undefined" || imageNode === null) {
        throw new Error("no image matches the map");
      }

      return imageNode;
    }
  }

  _frameOffset() {
    let win = window;
    let offset = { top: 0, left: 0 };

    while (win.frameElement) {
      let rect = win.frameElement.getClientRects()[0];
      let style = win.getComputedStyle(win.frameElement);
      win = win.parent;

      offset.top += rect.top + parseInt(style.getPropertyValue("padding-top"), 10)
      offset.left += rect.left + parseInt(style.getPropertyValue("padding-left"), 10)
    }

    return offset;
  }

  _getSelector(el) {
    let selector = (el.tagName != 'HTML') ? this._getSelector(el.parentNode) + " " : "";
    selector += el.tagName.toLowerCase();
    if (el.id) { selector += `#${el.id}` };
    el.classList.forEach(c => selector += `.${c}`);
    return selector;
  }

  _isInViewport(node) {
    let rect = node.getBoundingClientRect();
    return rect.top >= 0 &&
           rect.left >= 0 &&
           rect.bottom <= window.innerHeight &&
           rect.right <= window.innerWidth;
  }

  select(node, value) {
    if (this.isDisabled(node)) {
      return false;
    } else if (value == false && !node.parentNode.multiple) {
      return false;
    } else {
      this.trigger("focus", {}, node.parentNode);

      node.selected = value;
      this.changed(node);

      this.trigger("blur", {}, node.parentNode)
      return true;
    }
  }

  changed(node) {
    let element;
    let event = document.createEvent("HTMLEvents");
    event.initEvent("change", true, false);

    // In the case of an OPTION tag, the change event should come
    // from the parent SELECT
    if (node.nodeName == "OPTION") {
      element = node.parentNode
      if (element.nodeName == "OPTGROUP") {
        element = element.parentNode
      }
      element
    } else {
      element = node
    }

    element.dispatchEvent(event)
  }

  trigger(name, options = {}, element) {
    let event;

    if (EVENTS.MOUSE.indexOf(name) != -1) {
      event = document.createEvent("MouseEvent");
      event.initMouseEvent(
        name, true, true, window, 0,
        options["screenX"] || 0, options["screenY"] || 0,
        options["clientX"] || 0, options["clientY"] || 0,
        options["ctrlKey"] || false,
        options["altKey"] || false,
        options["shiftKey"] || false,
        options["metaKey"] || false,
        options["button"] || 0, null
      )
    } else if (EVENTS.FOCUS.indexOf(name) != -1) {
      event = this.obtainEvent(name);
    } else if (EVENTS.FORM.indexOf(name) != -1) {
      event = this.obtainEvent(name);
    } else {
      throw "Unknown event";
    }

    element.dispatchEvent(event);
  }

  obtainEvent(name) {
    let event = document.createEvent("HTMLEvents");
    event.initEvent(name, true, true);
    return event;
  }

  getAttributes(node) {
    let attrs = {};
    for (let i = 0, len = node.attributes.length; i < len; i++) {
      let attr = node.attributes[i];
      attrs[attr.name] = attr.value.replace("\n", "\\n");
    }

    return JSON.stringify(attrs);
  }

  getAttribute(node, name) {
    if (name == "checked" || name == "selected") {
      return node[name];
    } else {
      return node.getAttribute(name);
    }
  }

  value(node) {
    if (node.tagName == "SELECT" && node.multiple) {
      let result = []

      for (let i = 0, len = node.children.length; i < len; i++) {
        let option = node.children[i];
        if (option.selected) {
          result.push(option.value);
        }
      }

      return result;
    } else {
      return node.value;
    }
  }
}

window._cuprite = new Cuprite;
