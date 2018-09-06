class InvalidSelector extends Error {}

const EVENTS = {
  FOCUS: ['blur', 'focus', 'focusin', 'focusout'],
  MOUSE: ['click', 'dblclick', 'mousedown', 'mouseenter', 'mouseleave',
          'mousemove', 'mouseover', 'mouseout', 'mouseup', 'contextmenu'],
  FORM: ['submit']
}

class Cuprite {
  find(method, selector, within = document) {
    try {
      let results = []

      if (method == "xpath") {
        let xpath = document.evaluate(selector, within, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null)
        for (let i = 0; i < xpath.snapshotLength; i++) {
          results.push(xpath.snapshotItem(i))
        }
      } else {
        results = within.querySelectorAll(selector)
      }

      return results;
    } catch (error) {
      // DOMException.INVALID_EXPRESSION_ERR is undefined, using pure code
      if (error.code == DOMException.SYNTAX_ERR || error.code == 51) {
        throw new InvalidSelector
      } else {
        throw error
      }
    }
  }

  isDisabled(node) {
    let xpath = 'parent::optgroup[@disabled] | \
                 ancestor::select[@disabled] | \
                 parent::fieldset[@disabled] | \
                 ancestor::*[not(self::legend) or preceding-sibling::legend][parent::fieldset[@disabled]]';

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
      let xpath = document.evaluate("./preceding-sibling::" + node.tagName, node, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);

      for (let i = 0; i < xpath.snapshotLength; i++) {
        prevSiblings.push(xpath.snapshotItem(i));
      }

      return node.tagName + "[" + (prevSiblings.length + 1) + "]";
    });

    return "//" + selectors.join('/');
  }

  scrollIntoViewport(node) {
    node.scrollIntoViewIfNeeded();

    if (!this._isInViewport(node)) {
      node.scrollIntoView({block: 'center', inline: 'center', behavior: 'instant'});
      return this._isInViewport(node);
    }

    return true;
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
      this.trigger('focus', {}, node.parentNode);

      node.selected = value;
      this.changed(node);

      this.trigger('blur', {}, node.parentNode)
      return true;
    }
  }

  changed(node) {
    let element;
    let event = document.createEvent('HTMLEvents');
    event.initEvent('change', true, false);

    // In the case of an OPTION tag, the change event should come
    // from the parent SELECT
    if (node.nodeName == 'OPTION') {
      element = node.parentNode
      if (element.nodeName == 'OPTGROUP') {
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
      event = document.createEvent('MouseEvent');
      event.initMouseEvent(
        name, true, true, window, 0,
        options['screenX'] || 0, options['screenY'] || 0,
        options['clientX'] || 0, options['clientY'] || 0,
        options['ctrlKey'] || false,
        options['altKey'] || false,
        options['shiftKey'] || false,
        options['metaKey'] || false,
        options['button'] || 0, null
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
    let event = document.createEvent('HTMLEvents');
    event.initEvent(name, true, true);
    return event;
  }
}

window._cuprite = new Cuprite;
