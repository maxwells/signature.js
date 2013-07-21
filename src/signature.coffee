class Signature

  # "constants"
  @NORTH_WEST = 0
  @NORTH = 1
  @NORTH_EAST = 2
  @WEST = 3
  @CENTER = 4
  @EAST = 5
  @SOUTH_WEST = 6
  @SOUTH = 7
  @SOUTH_EAST = 8

  # new Signature element
  # options requires:
  # - displayId: id of container DOM element
  # optional options:
  # - explanation: hash of elements to display some explanatory text
  #     requires:
  #       - text: String.
  #     optional:
  #       - font: String - what font to render (defaults to 'sans-serif')
  #       - color: String - what color to render (defaults to '#000')
  #       - size: int - what size to render text as (defaults to 10 point)
  #       - lineHeight: int - how far from top of one line to top of one below it (defaults to 1.2 * size)
  #       - maxWidth: int - how wide at most should text be before wrapping
  #       - position: int - cardinal/ordinal direction (or centered) - defaults to Signature.NORTH
  # - watermark: hash of elements to display a watermark
  #     requires:
  #       - url: String
  #     optional:
  #       - position: int - cardinal/ordinal direction (or centered) - defaults to Signature.CENTER
  #       - alpha: number - 0-1 value representing transparency (defaults to 0.2, or 20% visible)
  #       - scale: number representing size to scale by (1 = 100%, 3 = 300%, etc)
  #       - width: int - number of pixels wide (will override scale)
  #       - height: int - number of pixels tall (will override scale)
  # - http: hash of elements to handle saving base64 png
  #     requires:
  #       - address: String - web address to hit
  #     optional:
  #       - verb: String - POST/GET (defaults to POST, because GET won't work for large enough images due to length limits)
  #       - dataParam: String - what parameter to include base64 encoded png data in (defaults to "data")
  #       - onSave: function - callback with JSON.parsed result from server
  # - save: function (overrides built in http handling) - should take one parameter. this function will be passed the base64 encoded png data
  constructor: (options) ->
    alert "Signature requires a displayId in the options hash passed to it's constructor" unless options.displayId?
    @options = options

    @display = document.getElementById options.displayId

    @width = @display.clientWidth
    @height = @display.clientHeight

    @initialize()
  
  initialize: ->
    @hasDrawn = false 

    @initializeCanvas()

    @initializeHttp()

    @initializeExplanation() if @options.explanation?

    # watermark must be first thing drawn. If it is required,
    # then it must first be loaded before drawing signature pad
    if @options.watermark?
      @setWatermark(@options.watermark)
    else
      @setupPad()

    @setupListeners()

  initializeHttp: ->
    @options.http ||= {}
    @options.http.verb ||= 'POST'
    @options.http.dataParam ||= 'data'

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
      position = @determineWatermarkPosition options.position, width, height 
      @context.drawImage img, position.x, position.y, width, height
      
      @context.globalAlpha = 1
      @setupPad()

    imageObj.src = options.url

  # returns appropriate location {x,y} based on width and height of it
  # as well as cardinal/ordinal direction.
  determineWatermarkPosition: (position, width, height) =>
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

  # setup default explanation options
  initializeExplanation: ->
    @explanation = @options.explanation
    @explanation.size ||= 10
    @explanation.weight ||= "normal"
    @explanation.font ||= "sans-serif"
    @explanation.maxWidth ||= @display.offsetWidth
    @explanation.lineHeight ||= @explanation.size * 1.2
    @explanation.color ||= "#000"
    @explanation.position = Signature.NORTH unless @explanation.position?

  # add canvas as child of display
  initializeCanvas: ->
    @canvas = document.createElement 'canvas'
    @canvas.id = 'signature-canvas'
    @canvas.width = @width
    @canvas.height = @height
    @display.appendChild @canvas

    @context = @canvas.getContext("2d")

  # draw a line to canvas context
  # takes a hash with
  # - points: a list of {x,y} objects
  # - lineWidth: width of line to draw
  drawLine: (options) ->
    return unless options.points.length > 1
    @context.beginPath()
    @context.moveTo options.points[0].x, options.points[0].y
    for point in options.points.slice(1)
      @context.lineTo point.x, point.y
    @context.lineWidth = options.lineWidth ? 1
    @context.stroke()

  # draw explanation (if exists), and the x ______ stuff
  setupPad: ->
    @drawExplanation() if @options.explanation?

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
      
  # draws explanation based on position, font-size, font, font-weight, and max-width
  drawExplanation: ->
    @captureContextTextStyle()

    @context.font = "#{@explanation.weight} #{@explanation.size}px #{@explanation.font}"
    @context.textBaseline = "top"
    @context.fillStyle = @explanation.color

    position = {}
    
    # horizontal position and text alignment based on ordinal/cardinal direction
    switch(@explanation.position % 3)
      when 0
        @context.textAlign = "left"
        position.x = 0
      when 1
        @context.textAlign = "center"
        position.x = @width / 2
      when 2
        @context.textAlign = "right"
        position.x = @width

    lines = @wrapTextIfNecessary(@explanation.text, position.x, position.y, @explanation.maxWidth, @explanation.lineHeight)

    # vertical position based on ordinal/cardinal direction and number of lines of explanation text
    switch Math.floor(@explanation.position / 3)
      when 0 then position.y = 0
      when 1 then position.y = @height / 2 - lines.length * @explanation.lineHeight / 2
      when 2 then position.y = @height - lines.length * @explanation.lineHeight

    for line in lines
      @context.fillText(line, position.x, position.y);
      position.y += @explanation.lineHeight

    @restoreContextTextStyle()

  # squirrel away context text style state before some set of actions that requires changing them
  captureContextTextStyle: ->
    @contextFillStyle = @context.fillStyle
    @contextFontStyle = @context.font
    @contextTextBaseline = @context.textBaseline

  # reset context to previous state before some set of actions
  restoreContextTextStyle: ->
    @context.fillStyle = @contextFillStyle
    @context.font = @contextFontStyle
    @context.textBaseline = @contextTextBaseline

  # break up explanation text into multiple lines of content based on maxWidth (if necessary)
  wrapTextIfNecessary: (text, x, y, maxWidth, lineHeight) ->
    line = ''
    lines = []

    for word in text.split ' '
      testLine = "#{line}#{word} "
      if @context.measureText(testLine).width > maxWidth
        lines.push line
        line = "#{word} "
        y += lineHeight
      else
        line = testLine;
    lines.push line
    lines

  # references http://stackoverflow.com/questions/8567114/how-to-make-an-ajax-call-without-jquery
  # attempt to save to address provided with http verb provided in @options.http
  save: ->
    if (window.XMLHttpRequest) # code for IE7+, Firefox, Chrome, Opera, Safari
      xmlhttp = new XMLHttpRequest()
    else # code for IE6, IE5
      xmlhttp = new ActiveXObject("Microsoft.XMLHTTP")
  
    if @options.http.onSave?
      xmlhttp.onreadystatechange = =>
        @options.http.onSave JSON.parse(xmlhttp.responseText)
    else
      xmlhttp.onreadystatechange = =>
        if (xmlhttp.readyState==4 && xmlhttp.status==200)
          response = JSON.parse xmlhttp.responseText
  
    xmlhttp.open(@options.http.verb, @options.http.address, true)
    xmlhttp.setRequestHeader("Content-type", "application/x-www-form-urlencoded")
    console.log @asBase64PNG()
    xmlhttp.send("#{@options.http.dataParam}=#{@asBase64PNG()}")
  
  # save if a save callback was provided or else if http parameters
  acceptSignature: =>
    if @options.save?
      @options.save(@asBase64PNG())
    else
      @save() if @options.http?
    @clearAndRemoveButtons()

  rejectSignature: =>
    @clearAndRemoveButtons()

  # reset state
  clearAndRemoveButtons: ->
    @display.removeChild @canvas
    @display.removeChild @accept
    @display.removeChild @reject
    @initialize()

  # show accept/reject buttons
  displayAcceptReject: ->
    @accept = document.createElement 'button'
    @accept.className = @options.buttonClass if @options.buttonClass?
    @accept.innerHTML = "Accept"
    @accept.onmouseup = @acceptSignature
    @display.appendChild @accept

    @reject = document.createElement 'button'
    @reject.className = @options.buttonClass if @options.buttonClass?
    @reject.innerHTML = "Reject"
    @reject.onmouseup = @rejectSignature
    @display.appendChild @reject

  # export base64 encoded png version of image from canvas context
  asBase64PNG: ->
    @canvas.toDataURL('image/png').replace(/^data:image\/png;base64,/, "")

  setupListeners: ->
    @display.onmousedown = @onMouseDown
    @display.onmouseup = @onMouseUp
    @display.onmouseout = @onMouseOut
    @display.onmousemove = @onMouseMove

    @display.addEventListener("touchstart", @touchHandler, true);
    @display.addEventListener("touchmove", @touchHandler, true);
    @display.addEventListener("touchend", @touchHandler, true);
    @display.addEventListener("touchcancel", @touchHandler, true);

  # thanks to http://stackoverflow.com/questions/1517924/javascript-mapping-touch-events-to-mouse-events
  # takes a touch event and translates it into it's corresponding mouse event
  # to allow handling with one function
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
                              false, false, false, 0, null)

    first.target.dispatchEvent simulatedEvent
    e.preventDefault()

  # if drawing, toggle accept/reject buttons if they haven't already
  # been. Then draw a line from previous point to new one.
  onMouseMove: (e) =>
    if @drawing
      
      # show accept and reject buttons once some drawing has happened
      @displayAcceptReject() unless @hasDrawn
      @hasDrawn = true

      @newPoint = 
        x: e.offsetX ? e.layerX - @display.offsetLeft
        y: e.offsetY ? e.layerY - @display.offsetTop
      @drawLine
        points: [@prevPoint, @newPoint]
        lineWidth: 2
      @prevPoint = @newPoint
      console.log 'drawing'

  # start drawing and track previous point
  onMouseDown: (e) =>
    @drawing = true
    @prevPoint =
      x: e.offsetX ? e.layerX - @display.offsetLeft
      y: e.offsetY ? e.layerY - @display.offsetTop

  # stop drawing
  onMouseUp: =>
    @drawing = false

  # stop drawing
  onMouseOut: =>
    @drawing = false

window.Signature = Signature