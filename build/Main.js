Elm.Main = Elm.Main || {};
Elm.Main.make = function (_elm) {
   "use strict";
   _elm.Main = _elm.Main || {};
   if (_elm.Main.values)
   return _elm.Main.values;
   var _op = {},
   _N = Elm.Native,
   _U = _N.Utils.make(_elm),
   _L = _N.List.make(_elm),
   _A = _N.Array.make(_elm),
   _E = _N.Error.make(_elm),
   $moduleName = "Main",
   $Basics = Elm.Basics.make(_elm),
   $Config = Elm.Config.make(_elm),
   $Data = Elm.Data.make(_elm),
   $Drawing = Elm.Drawing.make(_elm),
   $Graphics$Element = Elm.Graphics.Element.make(_elm),
   $Logic = Elm.Logic.make(_elm),
   $Mouse = Elm.Mouse.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $Time = Elm.Time.make(_elm);
   var sampleTime = function (s) {
      return $Signal.lift($Basics.fst)($Time.timestamp(s));
   };
   var score = function (g) {
      return A3($Signal.foldp,
      $Basics.max,
      0,
      A2($Signal.lift,
      function ($) {
         return $Basics.truncate(function (_) {
            return _.y;
         }(function (_) {
            return _.me;
         }($)));
      },
      g));
   };
   var inputs = function () {
      var ticker = $Time.fps(30);
      return $Signal.sampleOn(ticker)(A3($Signal.lift2,
      F2(function (dt,rt) {
         return {_: {}
                ,dt: dt
                ,rodTarget: rt};
      }),
      ticker,
      A3($Signal.lift2,
      F2(function (v0,v1) {
         return {ctor: "_Tuple2"
                ,_0: v0
                ,_1: v1};
      }),
      $Mouse.isDown,
      A2($Signal.lift,
      $Data.toFloatPoint,
      $Mouse.position))));
   }();
   var main = function () {
      var game = A3($Signal.foldp,
      F2(function (x,y) {
         return x(y);
      }),
      A2($Logic.initial,
      $Config.canvasWidth,
      $Config.canvasHeight),
      A2($Signal.lift,
      $Logic.runGame,
      inputs));
      return A2($Signal._op["~"],
      A2($Signal._op["~"],
      A2($Signal._op["~"],
      A2($Signal._op["<~"],
      $Drawing.draw,
      game),
      score(game)),
      sampleTime(game)),
      $Mouse.position);
   }();
   _elm.Main.values = {_op: _op
                      ,inputs: inputs
                      ,score: score
                      ,sampleTime: sampleTime
                      ,main: main};
   return _elm.Main.values;
};Elm.Logic = Elm.Logic || {};
Elm.Logic.make = function (_elm) {
   "use strict";
   _elm.Logic = _elm.Logic || {};
   if (_elm.Logic.values)
   return _elm.Logic.values;
   var _op = {},
   _N = Elm.Native,
   _U = _N.Utils.make(_elm),
   _L = _N.List.make(_elm),
   _A = _N.Array.make(_elm),
   _E = _N.Error.make(_elm),
   $moduleName = "Logic",
   $Basics = Elm.Basics.make(_elm),
   $Config = Elm.Config.make(_elm),
   $Data = Elm.Data.make(_elm),
   $Generator = Elm.Generator.make(_elm),
   $Generator$Standard = Elm.Generator.Standard.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm);
   var updateView = function (g) {
      return function () {
         var view = g.view;
         var newView = _U.replace([["x"
                                   ,A2($Basics.max,
                                   g.me.x - 100,
                                   g.view.x)]
                                  ,["y",g.me.y]],
         view);
         return _U.replace([["view"
                            ,newView]],
         g);
      }();
   };
   var addRod = F4(function (dt,
   _v0,
   g,
   moved) {
      return function () {
         switch (_v0.ctor)
         {case "_Tuple2":
            return _U.eq(_v0._0,
              g.me.lastMouseDown) ? moved : _U.eq(_v0._0,
              false) ? _U.replace([["rod"
                                   ,$Maybe.Nothing]
                                  ,["lastMouseDown",false]],
              moved) : function () {
                 var _v4 = A3($Data.cursorTrace,
                 g.me,
                 g.platforms,
                 _v0._1);
                 switch (_v4.ctor)
                 {case "Just":
                    switch (_v4._0.ctor)
                      {case "_Tuple2":
                         return _U.replace([["rod"
                                            ,_U.cmp(g.me.stunTime,
                                            0) > 0 ? $Maybe.Nothing : $Maybe.Just({_: {}
                                                                                  ,x: _v4._0._0
                                                                                  ,y: _v4._0._1})]
                                           ,["lastMouseDown",true]],
                           moved);}
                      break;
                    case "Nothing":
                    return _U.replace([["rod"
                                       ,$Maybe.Nothing]
                                      ,["lastMouseDown",true]],
                      moved);}
                 _E.Case($moduleName,
                 "between lines 99 and 105");
              }();}
         _E.Case($moduleName,
         "between lines 97 and 105");
      }();
   });
   var updateStun = F2(function (dt,
   me) {
      return _U.replace([["stunTime"
                         ,A2($Basics.max,
                         0,
                         me.stunTime - dt)]],
      me);
   });
   var updateRod = F2(function (dt,
   me) {
      return function () {
         var _v8 = me.rod;
         switch (_v8.ctor)
         {case "Just":
            return function () {
                 var newRod = _U.replace([["x"
                                          ,_v8._0.x - $Config.platformSpeed(me.y) * dt]],
                 _v8._0);
                 return _U.replace([["rod"
                                    ,$Maybe.Just(newRod)]],
                 me);
              }();
            case "Nothing": return me;}
         _E.Case($moduleName,
         "between lines 88 and 91");
      }();
   });
   var removeInvisible = function (v) {
      return $List.filter(function (b) {
         return _U.cmp(b.x + b.w / 2,
         v.x - v.w / 2) > 0 && _U.cmp(b.x - b.w / 2,
         v.x + v.w / 2) < 0;
      });
   };
   var viewCollide = F3(function (dt,
   v,
   me) {
      return _U.cmp(me.x,
      v.x - v.w / 2 + $Config.meWidth / 2) < 1 && _U.cmp(me.dx,
      0) < 1 ? _U.replace([["x"
                           ,v.x - v.w / 2 + $Config.meWidth / 2]
                          ,["dx",0]
                          ,["rod",$Maybe.Nothing]
                          ,["stunTime"
                           ,_U.cmp(me.dx,
                           0) < 0 ? $Config.barrierStunTime : me.stunTime]],
      me) : me;
   });
   var groundCollide = function (me) {
      return _U.cmp(me.y,
      0) < 1 ? _U.replace([["y",0]
                          ,["dy",0]
                          ,["dx",0]],
      me) : me;
   };
   var posDistance = F2(function (p1,
   p2) {
      return $Basics.sqrt(Math.pow(p1.x - p2.x,
      2) + Math.pow(p1.y - p2.y,2));
   });
   var unitVector = F2(function (from,
   to) {
      return function () {
         var dist = A2(posDistance,
         from,
         to);
         return {ctor: "_Tuple2"
                ,_0: (to.x - from.x) / dist
                ,_1: (to.y - from.y) / dist};
      }();
   });
   var applyRodForce = F2(function (dt,
   me) {
      return function () {
         var _v10 = me.rod;
         switch (_v10.ctor)
         {case "Just":
            return function () {
                 var len = A2(posDistance,
                 me,
                 _v10._0);
                 return _U.cmp(len,
                 $Config.rodRestLength) < 1 ? me : function () {
                    var $ = A2(unitVector,
                    me,
                    _v10._0),
                    ux = $._0,
                    uy = $._1;
                    var acc = len * $Config.rodElasticity / $Config.meMass;
                    return _U.replace([["dx"
                                       ,me.dx + acc * ux * dt]
                                      ,["dy",me.dy + acc * uy * dt]],
                    me);
                 }();
              }();
            case "Nothing": return me;}
         _E.Case($moduleName,
         "between lines 44 and 51");
      }();
   });
   var applyDamping = F2(function (dt,
   me) {
      return function () {
         var velFactor = (0 - $Config.damping) / $Config.meMass * dt;
         return _U.replace([["dx"
                            ,me.dx + velFactor * me.dx]
                           ,["dy"
                            ,me.dy + velFactor * me.dy]],
         me);
      }();
   });
   var applyGravity = F2(function (dt,
   me) {
      return _U.replace([["dy"
                         ,me.dy - $Config.gravity * dt]],
      me);
   });
   var connectedAcceleration = F2(function (me,
   rod) {
      return function () {
         var theta = $Basics.snd($Basics.toPolar({ctor: "_Tuple2"
                                                 ,_0: rod.x - me.x
                                                 ,_1: rod.y - me.y}));
         var cost = $Basics.cos(theta);
         return $Basics.fromPolar({ctor: "_Tuple2"
                                  ,_0: $Config.meMass * $Config.gravity * cost
                                  ,_1: _U.cmp(cost,
                                  0) > 0 ? theta - $Basics.pi / 2 : theta + $Basics.pi / 2});
      }();
   });
   var initial = F2(function (w,
   h) {
      return {_: {}
             ,me: {_: {}
                  ,dx: 0
                  ,dy: 0
                  ,lastMouseDown: false
                  ,rod: $Maybe.Nothing
                  ,stunTime: 0
                  ,x: 0
                  ,y: 0}
             ,platforms: _L.fromArray([])
             ,randGen: $Generator$Standard.generator(0)
             ,timeSinceAdded: $Config.timeBetweenPlatforms(0)
             ,view: {_: {}
                    ,h: $Basics.toFloat(h)
                    ,w: $Basics.toFloat(w)
                    ,x: 0
                    ,y: 0}};
   });
   var updateMoving = F2(function (dt,
   p) {
      return _U.replace([["x"
                         ,p.x + dt * p.dx]
                        ,["y",p.y + dt * p.dy]],
      p);
   });
   var updatePlatforms = F2(function (dt,
   g) {
      return function () {
         var shouldAddNew = _U.cmp(g.timeSinceAdded,
         $Config.timeBetweenPlatforms(g.me.y)) > -1;
         var newTime = shouldAddNew ? 0 : g.timeSinceAdded + dt;
         return shouldAddNew ? function () {
            var $ = $Generator.$float(g.randGen),
            randVal = $._0,
            gen$ = $._1;
            var addNew = function (ps) {
               return A2($List._op["::"],
               {_: {}
               ,dx: 0 - $Config.platformSpeed(g.me.y)
               ,dy: 0
               ,h: 10
               ,w: $Config.platformWidth
               ,x: g.view.w / 2 + $Config.platformWidth / 2 + g.view.x
               ,y: 50 + randVal * 200 + g.view.y},
               ps);
            };
            return _U.replace([["platforms"
                               ,addNew(removeInvisible(g.view)(A2($List.map,
                               updateMoving(dt),
                               g.platforms)))]
                              ,["timeSinceAdded",newTime]
                              ,["randGen",gen$]],
            g);
         }() : _U.replace([["platforms"
                           ,removeInvisible(g.view)(A2($List.map,
                           updateMoving(dt),
                           g.platforms))]
                          ,["timeSinceAdded",newTime]],
         g);
      }();
   });
   var updateMe = F3(function (dt,
   _v12,
   g) {
      return function () {
         switch (_v12.ctor)
         {case "_Tuple2":
            return _U.replace([["me"
                               ,updateRod(dt)(A3(addRod,
                               dt,
                               {ctor: "_Tuple2"
                               ,_0: _v12._0
                               ,_1: _v12._1},
                               g)(A2(viewCollide,
                               dt,
                               g.view)(groundCollide(updateMoving(dt)(applyGravity(dt)(applyRodForce(dt)(applyDamping(dt)(updateStun(dt)(g.me)))))))))]],
              g);}
         _E.Case($moduleName,
         "between lines 108 and 117");
      }();
   });
   var runGame = F2(function (_v16,
   g) {
      return function () {
         return updateView(updatePlatforms(_v16.dt)(A3(updateMe,
         _v16.dt,
         function (_v18) {
            return function () {
               switch (_v18.ctor)
               {case "_Tuple2":
                  return {ctor: "_Tuple2"
                         ,_0: _v18._0
                         ,_1: A2($Data.toGameCoords,
                         g.view,
                         _v18._1)};}
               _E.Case($moduleName,
               "on line 128, column 55 to 79");
            }();
         }(_v16.rodTarget),
         g)));
      }();
   });
   _elm.Logic.values = {_op: _op
                       ,updateMoving: updateMoving
                       ,initial: initial
                       ,connectedAcceleration: connectedAcceleration
                       ,applyGravity: applyGravity
                       ,applyDamping: applyDamping
                       ,posDistance: posDistance
                       ,unitVector: unitVector
                       ,applyRodForce: applyRodForce
                       ,groundCollide: groundCollide
                       ,viewCollide: viewCollide
                       ,removeInvisible: removeInvisible
                       ,updatePlatforms: updatePlatforms
                       ,updateRod: updateRod
                       ,updateStun: updateStun
                       ,addRod: addRod
                       ,updateMe: updateMe
                       ,updateView: updateView
                       ,runGame: runGame};
   return _elm.Logic.values;
};Elm.Drawing = Elm.Drawing || {};
Elm.Drawing.make = function (_elm) {
   "use strict";
   _elm.Drawing = _elm.Drawing || {};
   if (_elm.Drawing.values)
   return _elm.Drawing.values;
   var _op = {},
   _N = Elm.Native,
   _U = _N.Utils.make(_elm),
   _L = _N.List.make(_elm),
   _A = _N.Array.make(_elm),
   _E = _N.Error.make(_elm),
   $moduleName = "Drawing",
   $Basics = Elm.Basics.make(_elm),
   $Color = Elm.Color.make(_elm),
   $Config = Elm.Config.make(_elm),
   $Data = Elm.Data.make(_elm),
   $Graphics$Collage = Elm.Graphics.Collage.make(_elm),
   $Graphics$Element = Elm.Graphics.Element.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $String = Elm.String.make(_elm),
   $Text = Elm.Text.make(_elm),
   $Time = Elm.Time.make(_elm);
   var barrier = function (t) {
      return $Graphics$Collage.moveX((0 - $Config.canvasWidth) / 2)($Graphics$Collage.filled($Config.barrierFill(t))(A2($Graphics$Collage.rect,
      $Config.barrierWidth,
      $Config.canvasHeight)));
   };
   var removeOffset = F2(function (v,
   p) {
      return _U.replace([["y"
                         ,p.y - v.y]
                        ,["x",p.x - v.x]],
      p);
   });
   var drawRod = F3(function (v,
   me,
   rod) {
      return function () {
         var rodLine = $Graphics$Collage.solid($Config.rodColour);
         return $Graphics$Collage.traced(_U.replace([["width"
                                                     ,2]],
         rodLine))(A2($Graphics$Collage.segment,
         $Data.toPoint(A2(removeOffset,
         v,
         me)),
         $Data.toPoint(A2(removeOffset,
         v,
         rod))));
      }();
   });
   var drawRodTrace = F2(function (g,
   _v0) {
      return function () {
         switch (_v0.ctor)
         {case "_Tuple2":
            return function () {
                 var _v4 = A2($Data.cursorTrace,
                 g.me,
                 g.platforms)($Data.toGameCoords(g.view)($Data.toFloatPoint({ctor: "_Tuple2"
                                                                            ,_0: _v0._0
                                                                            ,_1: _v0._1})));
                 switch (_v4.ctor)
                 {case "Just":
                    switch (_v4._0.ctor)
                      {case "_Tuple2":
                         return A2($Graphics$Collage.traced,
                           $Graphics$Collage.solid($Config.cursorTraceDetectedColour),
                           A2($Graphics$Collage.segment,
                           $Data.toPoint(A2(removeOffset,
                           g.view,
                           g.me)),
                           {ctor: "_Tuple2"
                           ,_0: _v4._0._0 - g.view.x
                           ,_1: _v4._0._1 - g.view.y}));}
                      break;
                    case "Nothing":
                    return A2($Graphics$Collage.traced,
                      $Graphics$Collage.solid($Config.cursorTraceColour),
                      A2($Graphics$Collage.segment,
                      $Data.toPoint(A2(removeOffset,
                      g.view,
                      g.me)),
                      {ctor: "_Tuple2"
                      ,_0: $Basics.toFloat(_v0._0) - g.view.w / 2
                      ,_1: g.view.h / 2 - $Basics.toFloat(_v0._1)}));}
                 _E.Case($moduleName,
                 "between lines 33 and 41");
              }();}
         _E.Case($moduleName,
         "between lines 33 and 41");
      }();
   });
   var filledBox = F3(function (v,
   c,
   b) {
      return $Graphics$Collage.move({ctor: "_Tuple2"
                                    ,_0: b.x - v.x
                                    ,_1: b.y - v.y})($Graphics$Collage.filled(c)(A2($Graphics$Collage.rect,
      b.w,
      b.h)));
   });
   var blend = F3(function (x,
   c1,
   c2) {
      return function () {
         var inter = F3(function (x,
         a,
         b) {
            return $Basics.truncate(x * $Basics.toFloat(a) + (1 - x) * $Basics.toFloat(b));
         });
         var rgb2 = $Color.toRgb(c2);
         var rgb1 = $Color.toRgb(c1);
         return A3($Color.rgb,
         A3(inter,x,rgb1.red,rgb2.red),
         A3(inter,
         x,
         rgb1.green,
         rgb2.green),
         A3(inter,
         x,
         rgb1.blue,
         rgb2.blue));
      }();
   });
   var draw = F4(function (g,
   score,
   t,
   _v8) {
      return function () {
         switch (_v8.ctor)
         {case "_Tuple2":
            return A3($Graphics$Collage.collage,
              $Basics.truncate(g.view.w),
              $Basics.truncate(g.view.h),
              _L.append(_L.fromArray([A2($Graphics$Collage.filled,
              $Config.bgColour,
              A2($Graphics$Collage.rect,
              g.view.w,
              g.view.h))]),
              _L.append(_U.cmp(g.me.stunTime,
              0) > 0 || !_U.eq(g.me.rod,
              $Maybe.Nothing) ? _L.fromArray([]) : _L.fromArray([A2(drawRodTrace,
              g,
              {ctor: "_Tuple2"
              ,_0: _v8._0
              ,_1: _v8._1})]),
              _L.append(A2($List.map,
              A2(filledBox,
              g.view,
              $Config.platformColour),
              g.platforms),
              _L.append(function () {
                 var _v12 = g.me.rod;
                 switch (_v12.ctor)
                 {case "Just":
                    return _L.fromArray([A3(drawRod,
                      g.view,
                      g.me,
                      _v12._0)]);
                    case "Nothing":
                    return _L.fromArray([]);}
                 _E.Case($moduleName,
                 "between lines 59 and 61");
              }(),
              _L.append(_L.fromArray([A3(filledBox,
              g.view,
              _U.cmp(g.me.stunTime,
              0) > 0 ? A3(blend,
              g.me.stunTime / $Config.barrierStunTime,
              $Config.meStunnedColour,
              $Config.meColour) : $Config.meColour,
              {_: {}
              ,h: $Config.meWidth
              ,w: $Config.meWidth
              ,x: g.me.x
              ,y: g.me.y})]),
              _L.append(_L.fromArray([barrier(t)]),
              _L.append(_L.fromArray([A3(filledBox,
              g.view,
              $Config.groundColour,
              {_: {}
              ,h: g.view.h
              ,w: g.view.w
              ,x: g.view.x
              ,y: (0 - g.view.h) / 2 - $Config.meWidth / 2})]),
              _L.fromArray([$Graphics$Collage.move({ctor: "_Tuple2"
                                                   ,_0: -400
                                                   ,_1: 250})($Graphics$Collage.toForm($Text.centered($Text.style($Config.scoreStyle)($Text.toText(_L.append("Height: ",
                           $String.show($Basics.truncate(g.me.y))))))))
                           ,$Graphics$Collage.move({ctor: "_Tuple2"
                                                   ,_0: -400
                                                   ,_1: 270})($Graphics$Collage.toForm($Text.centered($Text.style($Config.scoreStyle)($Text.toText(_L.append("Score: ",
                           $String.show(score)))))))])))))))));}
         _E.Case($moduleName,
         "between lines 49 and 72");
      }();
   });
   _elm.Drawing.values = {_op: _op
                         ,blend: blend
                         ,filledBox: filledBox
                         ,removeOffset: removeOffset
                         ,drawRod: drawRod
                         ,drawRodTrace: drawRodTrace
                         ,barrier: barrier
                         ,draw: draw};
   return _elm.Drawing.values;
};Elm.Data = Elm.Data || {};
Elm.Data.make = function (_elm) {
   "use strict";
   _elm.Data = _elm.Data || {};
   if (_elm.Data.values)
   return _elm.Data.values;
   var _op = {},
   _N = Elm.Native,
   _U = _N.Utils.make(_elm),
   _L = _N.List.make(_elm),
   _A = _N.Array.make(_elm),
   _E = _N.Error.make(_elm),
   $moduleName = "Data",
   $Basics = Elm.Basics.make(_elm),
   $Config = Elm.Config.make(_elm),
   $Generator = Elm.Generator.make(_elm),
   $Generator$Standard = Elm.Generator.Standard.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Time = Elm.Time.make(_elm);
   var lineInverse = F3(function (_v0,
   _v1,
   y) {
      return function () {
         switch (_v1.ctor)
         {case "_Tuple2":
            return function () {
                 switch (_v0.ctor)
                 {case "_Tuple2":
                    return _v0._0 + (y - _v0._1) * (_v1._0 - _v0._0) / (_v1._1 - _v0._1);}
                 _E.Case($moduleName,
                 "on line 39, column 33 to 59");
              }();}
         _E.Case($moduleName,
         "on line 39, column 33 to 59");
      }();
   });
   var findXCrossing = F3(function (src,
   _v8,
   tgt) {
      return function () {
         switch (_v8.ctor)
         {case "_Tuple2":
            return function () {
                 var xCrossing = A3(lineInverse,
                 {ctor: "_Tuple2"
                 ,_0: src.x
                 ,_1: src.y},
                 {ctor: "_Tuple2"
                 ,_0: _v8._0
                 ,_1: _v8._1},
                 tgt.y);
                 return _U.cmp(tgt.x - tgt.w / 2,
                 xCrossing) < 1 && (_U.cmp(tgt.x + tgt.w / 2,
                 xCrossing) > -1 && _U.eq(_U.cmp(_v8._1,
                 src.y) > 0,
                 _U.cmp(tgt.y,
                 src.y) > 0)) ? $Maybe.Just({ctor: "_Tuple2"
                                            ,_0: xCrossing
                                            ,_1: tgt.y}) : $Maybe.Nothing;
              }();}
         _E.Case($moduleName,
         "between lines 42 and 47");
      }();
   });
   var cursorTrace = F3(function (src,
   tgts,
   _v12) {
      return function () {
         switch (_v12.ctor)
         {case "_Tuple2":
            return function () {
                 var inRange = function (_v16) {
                    return function () {
                       switch (_v16.ctor)
                       {case "_Tuple2":
                          return _U.cmp($Basics.sqrt(Math.pow(src.x - _v16._0,
                            2) + Math.pow(src.y - _v16._1,
                            2)),
                            $Config.maxRodLength) < 0;}
                       _E.Case($moduleName,
                       "on line 50, column 50 to 105");
                    }();
                 };
                 var crossings = $List.sortBy(function (_v23) {
                    return function () {
                       switch (_v23.ctor)
                       {case "Just":
                          switch (_v23._0.ctor)
                            {case "_Tuple2":
                               return _v23._0._1;}
                            break;}
                       _E.Case($moduleName,
                       "on line 51, column 71 to 72");
                    }();
                 })($List.filter(function (_v20) {
                    return function () {
                       switch (_v20.ctor)
                       {case "Just":
                          return inRange(_v20._0);}
                       _E.Case($moduleName,
                       "on line 52, column 67 to 76");
                    }();
                 })($List.filter(F2(function (x,
                 y) {
                    return !_U.eq(x,y);
                 })($Maybe.Nothing))(A2($List.map,
                 A2(findXCrossing,
                 src,
                 {ctor: "_Tuple2"
                 ,_0: _v12._0
                 ,_1: _v12._1}),
                 tgts))));
                 return _U.eq(crossings,
                 _L.fromArray([])) ? $Maybe.Nothing : $List.head(crossings);
              }();}
         _E.Case($moduleName,
         "between lines 50 and 57");
      }();
   });
   var toGameCoords = F2(function (_v28,
   _v29) {
      return function () {
         switch (_v29.ctor)
         {case "_Tuple2":
            return function () {
                 return {ctor: "_Tuple2"
                        ,_0: _v28.x + _v29._0 - _v28.w / 2
                        ,_1: _v28.y - _v29._1 + _v28.h / 2};
              }();}
         _E.Case($moduleName,
         "on line 35, column 35 to 61");
      }();
   });
   var toFloatPoint = function (_v34) {
      return function () {
         switch (_v34.ctor)
         {case "_Tuple2":
            return {ctor: "_Tuple2"
                   ,_0: $Basics.toFloat(_v34._0)
                   ,_1: $Basics.toFloat(_v34._1)};}
         _E.Case($moduleName,
         "on line 32, column 23 to 43");
      }();
   };
   var toPoint = function (p) {
      return {ctor: "_Tuple2"
             ,_0: p.x
             ,_1: p.y};
   };
   var Inputs = F2(function (a,b) {
      return {_: {}
             ,dt: a
             ,rodTarget: b};
   });
   var Game = F5(function (a,
   b,
   c,
   d,
   e) {
      return {_: {}
             ,me: b
             ,platforms: c
             ,randGen: e
             ,timeSinceAdded: d
             ,view: a};
   });
   var MovingBox = F7(function (a,
   b,
   c,
   d,
   e,
   f,
   g) {
      return _U.insert("h",
      f,
      _U.insert("w",
      e,
      _U.insert("dy",
      d,
      _U.insert("dx",
      c,
      _U.insert("y",
      b,
      _U.insert("x",a,g))))));
   });
   var Box = F5(function (a,
   b,
   c,
   d,
   e) {
      return _U.insert("h",
      d,
      _U.insert("w",
      c,
      _U.insert("y",
      b,
      _U.insert("x",a,e))));
   });
   var Moving = F5(function (a,
   b,
   c,
   d,
   e) {
      return _U.insert("dy",
      d,
      _U.insert("dx",
      c,
      _U.insert("y",
      b,
      _U.insert("x",a,e))));
   });
   var Positioned = F3(function (a,
   b,
   c) {
      return _U.insert("y",
      b,
      _U.insert("x",a,c));
   });
   _elm.Data.values = {_op: _op
                      ,Positioned: Positioned
                      ,Moving: Moving
                      ,Box: Box
                      ,MovingBox: MovingBox
                      ,Game: Game
                      ,Inputs: Inputs
                      ,toPoint: toPoint
                      ,toFloatPoint: toFloatPoint
                      ,toGameCoords: toGameCoords
                      ,lineInverse: lineInverse
                      ,findXCrossing: findXCrossing
                      ,cursorTrace: cursorTrace};
   return _elm.Data.values;
};Elm.Config = Elm.Config || {};
Elm.Config.make = function (_elm) {
   "use strict";
   _elm.Config = _elm.Config || {};
   if (_elm.Config.values)
   return _elm.Config.values;
   var _op = {},
   _N = Elm.Native,
   _U = _N.Utils.make(_elm),
   _L = _N.List.make(_elm),
   _A = _N.Array.make(_elm),
   _E = _N.Error.make(_elm),
   $moduleName = "Config",
   $Basics = Elm.Basics.make(_elm),
   $Color = Elm.Color.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Text = Elm.Text.make(_elm);
   var scoreStyle = _U.replace([["height"
                                ,$Maybe.Just(18)]],
   $Text.defaultStyle);
   var barrierFlashPeriod = 1000;
   var barrierFill = function (t) {
      return A4($Color.rgba,
      255,
      0,
      0,
      0.25 * $Basics.sin($Basics.toFloat(A2($Basics._op["%"],
      $Basics.truncate(t),
      barrierFlashPeriod)) * 2 * $Basics.pi / barrierFlashPeriod) + 0.25);
   };
   var barrierWidth = 10;
   var barrierGrad = function (t) {
      return A3($Color.linear,
      {ctor: "_Tuple2",_0: 0,_1: 0},
      {ctor: "_Tuple2"
      ,_0: barrierWidth - 10
      ,_1: 0},
      _L.fromArray([{ctor: "_Tuple2"
                    ,_0: 0
                    ,_1: A4($Color.rgba,
                    255,
                    0,
                    0,
                    0.25 * $Basics.sin($Basics.toFloat(A2($Basics._op["%"],
                    $Basics.truncate(t),
                    barrierFlashPeriod)) * 2 * $Basics.pi / barrierFlashPeriod) + 0.25)}
                   ,{ctor: "_Tuple2"
                    ,_0: 1
                    ,_1: A4($Color.rgba,
                    255,
                    0,
                    0,
                    1)}]));
   };
   var meWidth = 30;
   var barrierStunTime = 4000;
   var damping = 0.1;
   var rodElasticity = 1.0e-3;
   var rodRestLength = 60;
   var meMass = 200;
   var gravity = 4.0e-4;
   var maxRodLength = 1000;
   var platformWidth = 100;
   var platformSpeedIncreaseFactor = 2.0e-2;
   var platformSpeed = function (h) {
      return 0.2 * (h * platformSpeedIncreaseFactor + 100) / 100;
   };
   var timeBetweenPlatforms = function (h) {
      return 45 / platformSpeed(h);
   };
   var canvasHeight = 600;
   var canvasWidth = 1000;
   var hsv = F3(function (h,s,v) {
      return A3($Color.hsl,
      $Basics.degrees(h),
      s / 100,
      v / 100);
   });
   var meColour = A3(hsv,30,90,50);
   var meStunnedColour = A3(hsv,
   0,
   100,
   50);
   var rodColour = A3(hsv,
   30,
   90,
   50);
   var bgColour = A3(hsv,
   200,
   90,
   90);
   var groundColour = A3(hsv,
   200,
   70,
   20);
   var cursorTraceColour = groundColour;
   var cursorTraceDetectedColour = A3(hsv,
   0,
   100,
   50);
   var platformColour = A3(hsv,
   200,
   90,
   20);
   _elm.Config.values = {_op: _op
                        ,hsv: hsv
                        ,canvasWidth: canvasWidth
                        ,canvasHeight: canvasHeight
                        ,platformSpeedIncreaseFactor: platformSpeedIncreaseFactor
                        ,platformSpeed: platformSpeed
                        ,timeBetweenPlatforms: timeBetweenPlatforms
                        ,platformWidth: platformWidth
                        ,maxRodLength: maxRodLength
                        ,gravity: gravity
                        ,meMass: meMass
                        ,rodRestLength: rodRestLength
                        ,rodElasticity: rodElasticity
                        ,damping: damping
                        ,barrierStunTime: barrierStunTime
                        ,meWidth: meWidth
                        ,meColour: meColour
                        ,meStunnedColour: meStunnedColour
                        ,rodColour: rodColour
                        ,bgColour: bgColour
                        ,groundColour: groundColour
                        ,cursorTraceColour: cursorTraceColour
                        ,cursorTraceDetectedColour: cursorTraceDetectedColour
                        ,platformColour: platformColour
                        ,barrierWidth: barrierWidth
                        ,barrierFlashPeriod: barrierFlashPeriod
                        ,barrierFill: barrierFill
                        ,barrierGrad: barrierGrad
                        ,scoreStyle: scoreStyle};
   return _elm.Config.values;
};Elm.Generator = Elm.Generator || {};
Elm.Generator.Standard = Elm.Generator.Standard || {};
Elm.Generator.Standard.make = function (_elm) {
   "use strict";
   _elm.Generator = _elm.Generator || {};
   _elm.Generator.Standard = _elm.Generator.Standard || {};
   if (_elm.Generator.Standard.values)
   return _elm.Generator.Standard.values;
   var _op = {},
   _N = Elm.Native,
   _U = _N.Utils.make(_elm),
   _L = _N.List.make(_elm),
   _A = _N.Array.make(_elm),
   _E = _N.Error.make(_elm),
   $moduleName = "Generator.Standard",
   $Basics = Elm.Basics.make(_elm),
   $Generator = Elm.Generator.make(_elm);
   var magicNum8 = 2147483562;
   var stdRange = function (_v0) {
      return function () {
         return {ctor: "_Tuple2"
                ,_0: 0
                ,_1: magicNum8};
      }();
   };
   var magicNum7 = 2137383399;
   var magicNum6 = 2147483563;
   var magicNum5 = 3791;
   var magicNum4 = 40692;
   var magicNum3 = 52774;
   var magicNum2 = 12211;
   var magicNum1 = 53668;
   var magicNum0 = 40014;
   var Standard = F2(function (a,
   b) {
      return {ctor: "Standard"
             ,_0: a
             ,_1: b};
   });
   var mkStdGen = function (s$) {
      return function () {
         var s = A2($Basics.max,
         s$,
         0 - s$);
         var q = s / (magicNum6 - 1) | 0;
         var s2 = A2($Basics._op["%"],
         q,
         magicNum7 - 1);
         var s1 = A2($Basics._op["%"],
         s,
         magicNum6 - 1);
         return A2(Standard,
         s1 + 1,
         s2 + 1);
      }();
   };
   var stdNext = function (_v2) {
      return function () {
         switch (_v2.ctor)
         {case "Standard":
            return function () {
                 var k$ = _v2._1 / magicNum3 | 0;
                 var s2$ = magicNum4 * (_v2._1 - k$ * magicNum3) - k$ * magicNum5;
                 var s2$$ = _U.cmp(s2$,
                 0) < 0 ? s2$ + magicNum7 : s2$;
                 var k = _v2._0 / magicNum1 | 0;
                 var s1$ = magicNum0 * (_v2._0 - k * magicNum1) - k * magicNum2;
                 var s1$$ = _U.cmp(s1$,
                 0) < 0 ? s1$ + magicNum6 : s1$;
                 var z = s1$$ - s2$$;
                 var z$ = _U.cmp(z,
                 1) < 0 ? z + magicNum8 : z;
                 return {ctor: "_Tuple2"
                        ,_0: z$
                        ,_1: A2(Standard,s1$$,s2$$)};
              }();}
         _E.Case($moduleName,
         "between lines 58 and 66");
      }();
   };
   var stdSplit = function (_v6) {
      return function () {
         switch (_v6.ctor)
         {case "Standard":
            return function () {
                 var _raw = $Basics.snd(stdNext(_v6)),
                 $ = _raw.ctor === "Standard" ? _raw : _E.Case($moduleName,
                 "on line 72, column 28 to 44"),
                 t1 = $._0,
                 t2 = $._1;
                 var new_s2 = _U.eq(_v6._1,
                 1) ? magicNum7 - 1 : _v6._1 - 1;
                 var new_s1 = _U.eq(_v6._0,
                 magicNum6 - 1) ? 1 : _v6._0 + 1;
                 return {ctor: "_Tuple2"
                        ,_0: A2(Standard,new_s1,t2)
                        ,_1: A2(Standard,t1,new_s2)};
              }();}
         _E.Case($moduleName,
         "between lines 70 and 73");
      }();
   };
   var generator = function (seed) {
      return A4($Generator.Generator,
      mkStdGen(seed),
      stdNext,
      stdSplit,
      stdRange);
   };
   _elm.Generator.Standard.values = {_op: _op
                                    ,generator: generator};
   return _elm.Generator.Standard.values;
};Elm.Generator = Elm.Generator || {};
Elm.Generator.make = function (_elm) {
   "use strict";
   _elm.Generator = _elm.Generator || {};
   if (_elm.Generator.values)
   return _elm.Generator.values;
   var _op = {},
   _N = Elm.Native,
   _U = _N.Utils.make(_elm),
   _L = _N.List.make(_elm),
   _A = _N.Array.make(_elm),
   _E = _N.Error.make(_elm),
   $moduleName = "Generator",
   $Basics = Elm.Basics.make(_elm),
   $List = Elm.List.make(_elm);
   var Generator = F4(function (a,
   b,
   c,
   d) {
      return {_: {}
             ,next: b
             ,range: d
             ,split: c
             ,state: a};
   });
   var listOfHelp = F4(function (list,
   generate,
   n,
   generator) {
      return _U.cmp(n,
      1) < 0 ? {ctor: "_Tuple2"
               ,_0: $List.reverse(list)
               ,_1: generator} : function () {
         var $ = generate(generator),
         value = $._0,
         generator$ = $._1;
         return A4(listOfHelp,
         A2($List._op["::"],value,list),
         generate,
         n - 1,
         generator$);
      }();
   });
   var listOf = listOfHelp(_L.fromArray([]));
   var minInt32 = -2147483648;
   var maxInt32 = 2147483647;
   var iLogBase = F2(function (b,
   i) {
      return _U.cmp(i,
      b) < 0 ? 1 : 1 + A2(iLogBase,
      b,
      i / b | 0);
   });
   var int32Range = F2(function (_v0,
   generator) {
      return function () {
         switch (_v0.ctor)
         {case "_Tuple2":
            return _U.cmp(_v0._0,
              _v0._1) > 0 ? A2(int32Range,
              {ctor: "_Tuple2"
              ,_0: _v0._1
              ,_1: _v0._0},
              generator) : function () {
                 var b = 2147483561;
                 var f = F3(function (n,
                 acc,
                 state) {
                    return function () {
                       switch (n)
                       {case 0: return {ctor: "_Tuple2"
                                       ,_0: acc
                                       ,_1: state};}
                       return function () {
                          var $ = generator.next(state),
                          x = $._0,
                          state$ = $._1;
                          return A3(f,
                          n - 1,
                          x + acc * b,
                          state$);
                       }();
                    }();
                 });
                 var k = _v0._1 - _v0._0 + 1;
                 var n = A2(iLogBase,b,k);
                 var $ = A3(f,
                 n,
                 1,
                 generator.state),
                 v = $._0,
                 state$ = $._1;
                 return {ctor: "_Tuple2"
                        ,_0: _v0._0 + A2($Basics._op["%"],
                        v,
                        k)
                        ,_1: _U.replace([["state"
                                         ,state$]],
                        generator)};
              }();}
         _E.Case($moduleName,
         "between lines 73 and 86");
      }();
   });
   var floatRange = F2(function (_v5,
   generator) {
      return function () {
         switch (_v5.ctor)
         {case "_Tuple2":
            return _U.cmp(_v5._0,
              _v5._1) > 0 ? A2(floatRange,
              {ctor: "_Tuple2"
              ,_0: _v5._1
              ,_1: _v5._0},
              generator) : function () {
                 var $ = A2(int32Range,
                 {ctor: "_Tuple2"
                 ,_0: minInt32
                 ,_1: maxInt32},
                 generator),
                 x = $._0,
                 generator$ = $._1;
                 var scaled = (_v5._0 + _v5._1) / 2 + (_v5._1 - _v5._0) / $Basics.toFloat(maxInt32 - minInt32) * $Basics.toFloat(x);
                 return {ctor: "_Tuple2"
                        ,_0: scaled
                        ,_1: generator$};
              }();}
         _E.Case($moduleName,
         "between lines 117 and 122");
      }();
   });
   var $float = floatRange({ctor: "_Tuple2"
                           ,_0: 0
                           ,_1: 1});
   var int32 = int32Range({ctor: "_Tuple2"
                          ,_0: minInt32
                          ,_1: maxInt32});
   _elm.Generator.values = {_op: _op
                           ,int32: int32
                           ,int32Range: int32Range
                           ,$float: $float
                           ,floatRange: floatRange
                           ,listOf: listOf
                           ,minInt32: minInt32
                           ,maxInt32: maxInt32
                           ,Generator: Generator};
   return _elm.Generator.values;
};