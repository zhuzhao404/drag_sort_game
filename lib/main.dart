import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'DragSortGame'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ///当前随机的主题色
  var _color;

  ///色块集合
  List<Color> _colors = [];

  ///初始化颜色
  _shuffle() {
    _color = Colors.primaries[Random().nextInt(Colors.primaries.length)];
    _colors = List.generate(8, (index) => _color[(index + 1) * 100]!);

    ///主题跟随随机色
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: _color));
    setState(() {
      _colors.shuffle();
    });
  }

  ///检查颜色亮度排序,越亮证明颜色越浅
  _checkWinCondition() {
    bool win = true;
    for (int i = 0; i < _colors.length - 1; i++) {
      if (_colors[i].computeLuminance() > _colors[i + 1].computeLuminance()) {
        ///亮度大 证明浅色排在前了 返回false
        win = false;
        break;
      }
    }
    if (win) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('排序成功'),
          duration: Duration(milliseconds: 400),
        ),
      );
    }
  }

  final _globalKey = GlobalKey();

  ///记录当前拖拽的Box的index
  int _currentBoxIndex = 0;

  ///主要是拿到Stack(也可以是其他widget)最上面的距屏幕最上方的距离
  double _offSet = 0;

  @override
  void initState() {
    super.initState();
    _shuffle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: _color,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _shuffle,
          )
        ],
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text("拖拽色块颜色从深到浅排序", style: TextStyle(fontSize: 30)),
            const SizedBox(height: 20),
            Expanded(
              child: Listener(
                onPointerMove: (event) {
                  final x = event.position.dx;
                  final y = event.position.dy - _offSet;

                  ///减去了当前stack顶部所在的位置
                  if (y > (_currentBoxIndex + 1) * Box.height) {
                    ///当按下的手势滑动到超过下一个的顶部边界
                    if (_currentBoxIndex == _colors.length - 1) return;
                    setState(() {
                      final currentColor = _colors[_currentBoxIndex];
                      _colors[_currentBoxIndex] = _colors[_currentBoxIndex + 1];
                      _colors[_currentBoxIndex + 1] = currentColor;
                      _currentBoxIndex++;
                    });
                  } else if (y < (_currentBoxIndex - 1) * Box.height) {
                    ///当按下的手势滑动到小于下一个的下方边界
                    if (_currentBoxIndex == 0) return;
                    setState(() {
                      final currentColor = _colors[_currentBoxIndex];
                      _colors[_currentBoxIndex] = _colors[_currentBoxIndex - 1];
                      _colors[_currentBoxIndex - 1] = currentColor;
                      _currentBoxIndex--;
                    });
                  } else if (_currentBoxIndex == 1 && y < Box.height) {
                    setState(() {
                      final currentColor = _colors[_currentBoxIndex];
                      _colors[_currentBoxIndex] = _colors[_currentBoxIndex - 1];
                      _colors[_currentBoxIndex - 1] = currentColor;
                      _currentBoxIndex--;
                    });
                  }
                },
                child: SizedBox(
                  width: Box.width,
                  child: Stack(
                    alignment: Alignment.center,
                    key: _globalKey,
                    children: List.generate(
                        _colors.length,
                        (index) => Box(
                              x: 0,
                              y: index * Box.height,
                              color: _colors[index],
                              onDrag: (color) {
                                ///当前box的拖拽回传
                                final currentIndex = _colors.indexOf(color);
                                _currentBoxIndex = currentIndex;
                                final renderBox = _globalKey.currentContext
                                    ?.findRenderObject() as RenderBox;
                                _offSet =
                                    renderBox.localToGlobal(Offset.zero).dy;
                              },
                              onDragEnd: () {
                                _checkWinCondition();
                              },
                            )),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

///色块组件
class Box extends StatelessWidget {
  final Color color;
  final double x, y;
  static const double width = 200;
  static const double height = 50;
  static const double margin = 3;
  final Function(Color) onDrag;
  final Function() onDragEnd;

  Box({
    required this.color,
    required this.x,
    required this.y,
    required this.onDrag,
    required this.onDragEnd,

    ///key方便animated进行动画需要记录之前的状态
  }) : super(key: ValueKey(color));

  @override
  Widget build(BuildContext context) {
    final container = Container(
      width: width - margin * 2,
      height: height - margin * 2,
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
    );

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      top: y,
      left: x,
      child: Draggable(
        ///当手指按下拖动时回传当前box的color,color更多的代表box的唯一
        onDragStarted: () => onDrag(color),
        onDragEnd: (detail) => onDragEnd(),

        ///拖动时原来的位置显示透明占位
        childWhenDragging: Visibility(
          child: container,
          visible: false,
        ),

        ///拖动显示的部分
        feedback: container,
        child: container,
      ),
    );
  }
}
