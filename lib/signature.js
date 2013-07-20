// Generated by CoffeeScript 1.4.0
(function() {
  var Signature, root,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Signature = (function() {

    Signature.NORTH_WEST = 1;

    Signature.NORTH = 2;

    Signature.NORTH_EAST = 3;

    Signature.WEST = 4;

    Signature.CENTER = 5;

    Signature.EAST = 6;

    Signature.SOUTH_WEST = 7;

    Signature.SOUTH = 8;

    Signature.SOUTH_EAST = 9;

    function Signature(options) {
      this.onMouseOver = __bind(this.onMouseOver, this);

      this.onMouseOut = __bind(this.onMouseOut, this);

      this.onMouseUp = __bind(this.onMouseUp, this);

      this.onMouseDown = __bind(this.onMouseDown, this);

      this.onMouseMove = __bind(this.onMouseMove, this);

      this.determinePosition = __bind(this.determinePosition, this);
      if (options.displayId == null) {
        alert("Signature requires a displayId in the options hash passed to it's constructor");
      }
      this.options = options;
      this.display = document.getElementById(options.displayId);
      this.width = this.display.clientWidth;
      this.height = this.display.clientHeight;
      this.initializeCanvas();
      if (options.watermark != null) {
        this.setWatermark(options.watermark);
      } else {
        this.setupPad();
      }
      this.setupListeners();
    }

    Signature.prototype.setWatermark = function(options) {
      var imageObj,
        _this = this;
      if (!options.url) {
        return;
      }
      options.position || (options.position = 5);
      options.scale || (options.scale = 1);
      options.alpha || (options.alpha = 0.2);
      imageObj = new Image();
      imageObj.onload = function(event) {
        var height, img, position, width, _ref, _ref1;
        img = event.currentTarget;
        _this.context.globalAlpha = options.alpha;
        width = (_ref = options.width) != null ? _ref : img.width * options.scale;
        height = (_ref1 = options.height) != null ? _ref1 : img.height * options.scale;
        position = _this.determinePosition(options.position, width, height);
        _this.context.drawImage(img, position.x, position.y, width, height);
        _this.context.globalAlpha = 1;
        return _this.setupPad();
      };
      return imageObj.src = options.url;
    };

    Signature.prototype.determinePosition = function(position, width, height) {
      var bottomY, centerX, centerY, rightX;
      centerX = (this.width - width) / 2;
      centerY = (this.height - height) / 2;
      rightX = this.width - width;
      bottomY = this.height - height;
      switch (position) {
        case Signature.NORTH_WEST:
          return {
            x: 0,
            y: 0
          };
        case Signature.NORTH:
          return {
            x: centerX,
            y: 0
          };
        case Signature.NORTH_EAST:
          return {
            x: rightX,
            y: 0
          };
        case Signature.WEST:
          return {
            x: 0,
            y: centerY
          };
        case Signature.CENTER:
          return {
            x: centerX,
            y: centerY
          };
        case Signature.EAST:
          return {
            x: rightX,
            y: centerY
          };
        case Signature.SOUTH_WEST:
          return {
            x: 0,
            y: bottomY
          };
        case Signature.SOUTH:
          return {
            x: centerX,
            y: bottomY
          };
        case Signature.SOUTH_EAST:
          return {
            x: rightX,
            y: bottomY
          };
      }
    };

    Signature.prototype.initializeCanvas = function() {
      this.canvas = document.createElement('canvas');
      this.canvas.id = 'signature-canvas';
      this.canvas.width = this.width;
      this.canvas.height = this.height;
      this.display.appendChild(this.canvas);
      return this.context = this.canvas.getContext("2d");
    };

    Signature.prototype.drawLine = function(options) {
      var point, _i, _len, _ref, _ref1;
      if (!(options.points.length > 1)) {
        return;
      }
      this.context.beginPath();
      this.context.moveTo(options.points[0].x, options.points[0].y);
      _ref = options.points.slice(1);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        point = _ref[_i];
        this.context.lineTo(point.x, point.y);
      }
      this.context.lineWidth = (_ref1 = options.lineWidth) != null ? _ref1 : 1;
      return this.context.stroke();
    };

    Signature.prototype.setupPad = function() {
      this.drawLine({
        points: [
          {
            x: 20,
            y: this.height - 15
          }, {
            x: this.width - 20,
            y: this.height - 15
          }
        ]
      });
      this.drawLine({
        points: [
          {
            x: 25,
            y: this.height - 32
          }, {
            x: 35,
            y: this.height - 22
          }
        ],
        lineWidth: 2
      });
      return this.drawLine({
        points: [
          {
            x: 35,
            y: this.height - 32
          }, {
            x: 25,
            y: this.height - 22
          }
        ],
        lineWidth: 2
      });
    };

    Signature.prototype.asBase64PNG = function() {
      return this.canvas.toDataURL('image/png').replace(/^data:image\/png;base64,/, "");
    };

    Signature.prototype.setupListeners = function() {
      this.display.onmousedown = this.onMouseDown;
      this.display.onmouseup = this.onMouseUp;
      this.display.onmouseout = this.onMouseOut;
      this.display.onmouseover = this.onMouseOver;
      this.display.onmousemove = this.onMouseMove;
      this.display.addEventListener("touchstart", this.touchHandler, true);
      this.display.addEventListener("touchmove", this.touchHandler, true);
      this.display.addEventListener("touchend", this.touchHandler, true);
      return this.display.addEventListener("touchcancel", this.touchHandler, true);
    };

    Signature.prototype.touchHandler = function(e) {
      var first, simulatedEvent, touches, type;
      touches = event.changedTouches;
      first = touches[0];
      type = "";
      switch (e.type) {
        case 'touchstart':
          type = 'mousedown';
          break;
        case 'touchstart':
          type = 'mousedown';
          break;
        case 'touchmove':
          type = 'mousemove';
          break;
        case 'touchend':
          type = 'mouseup';
      }
      simulatedEvent = document.createEvent("MouseEvent");
      simulatedEvent.initMouseEvent(type, true, true, window, 1, first.screenX, first.screenY, first.clientX, first.clientY, false, false, false, false, 0, null);
      first.target.dispatchEvent(simulatedEvent);
      return e.preventDefault();
    };

    Signature.prototype.onMouseMove = function(e) {
      var _ref, _ref1;
      if (this.drawing) {
        this.newPoint = {
          x: (_ref = e.offsetX) != null ? _ref : e.layerX - this.display.offsetLeft,
          y: (_ref1 = e.offsetY) != null ? _ref1 : e.layerY - this.display.offsetTop
        };
        this.drawLine({
          points: [this.prevPoint, this.newPoint],
          lineWidth: 2
        });
        this.prevPoint = this.newPoint;
        return console.log('drawing');
      }
    };

    Signature.prototype.onMouseDown = function(e) {
      var _ref, _ref1;
      this.drawing = true;
      this.prevPoint = {
        x: (_ref = e.offsetX) != null ? _ref : e.layerX - this.display.offsetLeft,
        y: (_ref1 = e.offsetY) != null ? _ref1 : e.layerY - this.display.offsetTop
      };
      return console.log(e);
    };

    Signature.prototype.onMouseUp = function() {
      return this.drawing = false;
    };

    Signature.prototype.onMouseOut = function() {
      return this.drawing = false;
    };

    Signature.prototype.onMouseOver = function() {};

    return Signature;

  })();

  root = typeof exports !== "undefined" && exports !== null ? exports : window;

  root.Signature = Signature;

}).call(this);