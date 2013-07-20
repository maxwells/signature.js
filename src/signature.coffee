class Signature

  @NORTH_WEST = 1
  @NORTH = 2
  @NORTH_EAST = 3
  @WEST = 4
  @CENTER = 5
  @EAST = 6
  @SOUTH_WEST = 7
  @SOUTH = 8
  @SOUTH_EAST = 9

  constructor: (options) ->
    alert "Signature requires a displayId in the options hash passed to it's constructor" unless options.displayId?
    @options = options

    @display = document.getElementById options.displayId

    @width = @display.clientWidth
    @height = @display.clientHeight

    @initializeCanvas()

    # watermark must be first thing drawn. If it is required,
    # then it must first be loaded before drawing signature pad
    if options.watermark?
      @setWatermark(options.watermark)
    else
      @setupPad()

    @setupListeners()

  # setting watermark takes the following options
  # - position: (defaults to center) representing any of the cardinal/ordinal directions, as defined above (use Signature.NORTH as accessor)
  # - scale: (defaults to 1) - scale factor
  # - alpha: (defaults to 0.2) transparancy of watermark
  # - width: (overrides scale) how wide it should be
  # - height: (overrides scale) how tall it should be
  setWatermark: (options) ->
    return unless options.url
    options.position ||= 5
    options.scale ||= 1
    options.alpha ||= 0.2

    imageObj = new Image()

    imageObj.onload = (event) =>
      img = event.currentTarget
      @context.globalAlpha = options.alpha
      
      width = options.width ? img.width * options.scale
      height = options.height ? img.height * options.scale
      position = @determinePosition options.position, width, height 
      @context.drawImage img, position.x, position.y, width, height
      
      @context.globalAlpha = 1
      @setupPad()

    imageObj.src = options.url

  determinePosition: (position, width, height) =>
    centerX = (@width - width) / 2
    centerY = (@height - height) / 2
    rightX = @width - width
    bottomY = @height - height
    switch position
      when Signature.NORTH_WEST then return x: 0, y: 0
      when Signature.NORTH then return x: centerX, y: 0
      when Signature.NORTH_EAST then return x: rightX, y: 0
      when Signature.WEST then return x: 0, y: centerY
      when Signature.CENTER then return x: centerX, y: centerY
      when Signature.EAST then return x: rightX, y: centerY
      when Signature.SOUTH_WEST then return x: 0, y: bottomY
      when Signature.SOUTH then return x: centerX, y: bottomY
      when Signature.SOUTH_EAST then return x: rightX, y: bottomY

  initializeCanvas: ->
    @canvas = document.createElement 'canvas'
    @canvas.id = 'signature-canvas'
    @canvas.width = @width
    @canvas.height = @height
    @display.appendChild @canvas

    @context = @canvas.getContext("2d")

  drawLine: (options) ->
    return unless options.points.length > 1
    @context.beginPath()
    @context.moveTo options.points[0].x, options.points[0].y
    for point in options.points.slice(1)
      @context.lineTo point.x, point.y
    @context.lineWidth = options.lineWidth ? 1
    @context.stroke()

  setupPad: ->
    @drawLine
      points: [{ x: 20, y: @height - 15 }, { x: @width - 20, y: @height - 15}]

    @drawLine
      points: [{ x: 25, y: @height - 32},
               { x: 35, y: @height - 22}]
      lineWidth: 2

    @drawLine
      points: [{ x: 35, y: @height - 32},
               { x: 25, y: @height - 22}]
      lineWidth: 2

  asBase64PNG: ->
    @canvas.toDataURL('image/png').replace(/^data:image\/png;base64,/, "")

  setupListeners: ->
    @display.onmousedown = @onMouseDown
    @display.onmouseup = @onMouseUp
    @display.onmouseout = @onMouseOut
    @display.onmouseover = @onMouseOver
    @display.onmousemove = @onMouseMove

    @display.addEventListener("touchstart", @touchHandler, true);
    @display.addEventListener("touchmove", @touchHandler, true);
    @display.addEventListener("touchend", @touchHandler, true);
    @display.addEventListener("touchcancel", @touchHandler, true);

  touchHandler: (e) ->
    touches = event.changedTouches
    first = touches[0]
    type = ""

    switch e.type
      when 'touchstart' then type = 'mousedown'
      when 'touchstart' then type = 'mousedown'
      when 'touchmove'  then type = 'mousemove'
      when 'touchend'   then type = 'mouseup'

    simulatedEvent = document.createEvent("MouseEvent");
    simulatedEvent.initMouseEvent(type, true, true, window, 1, 
                              first.screenX, first.screenY, 
                              first.clientX, first.clientY, false, 
                              false, false, false, 0, null);

    first.target.dispatchEvent(simulatedEvent);
    e.preventDefault();

  onMouseMove: (e) =>
    if @drawing
      @newPoint = 
        x: e.offsetX ? e.layerX - @display.offsetLeft
        y: e.offsetY ? e.layerY - @display.offsetTop
      @drawLine
        points: [@prevPoint, @newPoint]
        lineWidth: 2
      @prevPoint = @newPoint
      console.log 'drawing'

  onMouseDown: (e) =>
    @drawing = true
    @prevPoint =
      x: e.offsetX ? e.layerX - @display.offsetLeft
      y: e.offsetY ? e.layerY - @display.offsetTop
    console.log e

  onMouseUp: =>
    @drawing = false

  onMouseOut: =>
    @drawing = false

  onMouseOver: =>

root = exports ? window
root.Signature = Signature