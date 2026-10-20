// HTML5 drag-and-drop emulation.
//
// Ported from Capybara's Selenium driver (capybara/selenium/extensions/html5_drag.rb,
// HTML5_DRAG_DROP_SCRIPT), see https://github.com/rubycdp/cuprite/issues/314.
// Unlike the original, a drag ends the way it does in a browser: with `drop` if
// the target accepted it, otherwise with `dragleave`, never both [#325].

(function(source, target, step_delay, drop_modifier_keys, drop_offset, callback) {
  function rectCenter(rect){
    return new DOMPoint(
      (rect.left + rect.right)/2,
      (rect.top + rect.bottom)/2
    );
  }

  function pointOnRect(pt, rect) {
    var rectPt = rectCenter(rect);
    var slope = (rectPt.y - pt.y) / (rectPt.x - pt.x);

    if (pt.x <= rectPt.x) { // left side
      var minXy = slope * (rect.left - pt.x) + pt.y;
      if (rect.top <= minXy && minXy <= rect.bottom)
        return new DOMPoint(rect.left, minXy);
    }

    if (pt.x >= rectPt.x) { // right side
      var maxXy = slope * (rect.right - pt.x) + pt.y;
      if (rect.top <= maxXy && maxXy <= rect.bottom)
        return new DOMPoint(rect.right, maxXy);
    }

    if (pt.y <= rectPt.y) { // top side
      var minYx = (rect.top - pt.y) / slope + pt.x;
      if (rect.left <= minYx && minYx <= rect.right)
        return new DOMPoint(minYx, rect.top);
    }

    if (pt.y >= rectPt.y) { // bottom side
      var maxYx = (rect.bottom - pt.y) / slope + pt.x;
      if (rect.left <= maxYx && maxYx <= rect.right)
        return new DOMPoint(maxYx, rect.bottom);
    }

    return new DOMPoint(pt.x,pt.y);
  }

  function dragEnterTarget() {
    target.scrollIntoView({behavior: 'instant', block: 'center', inline: 'center'});
    var targetRect = target.getBoundingClientRect();
    var sourceCenter = rectCenter(source.getBoundingClientRect());

    for (var i = 0; i < drop_modifier_keys.length; i++) {
      var key = drop_modifier_keys[i];
      if (key == "control"){
        key = "ctrl"
      }
      opts[key + 'Key'] = true;
    }

    var dragEnterEvent = new DragEvent('dragenter', opts);
    target.dispatchEvent(dragEnterEvent);

    // fire 2 dragover events to simulate dragging with a direction
    var entryPoint = pointOnRect(sourceCenter, targetRect)
    var dragOverOpts = Object.assign({clientX: entryPoint.x, clientY: entryPoint.y}, opts);
    var dragOverEvent = new DragEvent('dragover', dragOverOpts);
    target.dispatchEvent(dragOverEvent);
    window.setTimeout(dragOnTarget, step_delay);
  }

  function dropPoint(rect) {
    if (!drop_offset) return rectCenter(rect);

    var origin = drop_offset.position == 'center' ? rectCenter(rect) : new DOMPoint(rect.left, rect.top);
    return new DOMPoint(origin.x + drop_offset.x, origin.y + drop_offset.y);
  }

  function dragOnTarget() {
    var point = dropPoint(target.getBoundingClientRect());
    var dragOverOpts = Object.assign({clientX: point.x, clientY: point.y}, opts);
    var dragOverEvent = new DragEvent('dragover', dragOverOpts);
    target.dispatchEvent(dragOverEvent);
    window.setTimeout(dragEnd, step_delay, dragOverEvent.defaultPrevented, dragOverOpts);
  }

  function dragEnd(drop, dragOverOpts) {
    var dragEndOptions = Object.assign({}, opts, dragOverOpts);
    var dropOrLeaveEvent = new DragEvent(drop ? 'drop' : 'dragleave', dragEndOptions);
    target.dispatchEvent(dropOrLeaveEvent);
    var dragEndEvent = new DragEvent('dragend', dragEndOptions);
    source.dispatchEvent(dragEndEvent);
    callback.call(true);
  }

  var dt = new DataTransfer();
  var opts = { cancelable: true, bubbles: true, dataTransfer: dt };

  while (source && !source.draggable) {
    source = source.parentElement;
  }

  if (source.tagName == 'A'){
    dt.setData('text/uri-list', source.href);
    dt.setData('text', source.href);
  }
  if (source.tagName == 'IMG'){
    dt.setData('text/uri-list', source.src);
    dt.setData('text', source.src);
  }

  var dragEvent = new DragEvent('dragstart', opts);
  source.dispatchEvent(dragEvent);

  window.setTimeout(dragEnterTarget, step_delay);
}).apply(this, arguments);
