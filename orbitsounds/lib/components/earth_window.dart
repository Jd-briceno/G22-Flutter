import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomSvgImageFill extends StatefulWidget {
  const CustomSvgImageFill({super.key});

  @override
  State<CustomSvgImageFill> createState() => _CustomSvgImageFillState();
}

class _CustomSvgImageFillState extends State<CustomSvgImageFill> {
  ui.Image? _image;

  // Ruta del path extraída directamente
  static const String pathD =
      'M328.837 0.5C330.355 0.500025 331.806 1.12777 332.846 2.23438L343.922 14.0254C345.783 16.007 345.917 19.0508 344.237 21.1885L342.462 23.4492C341.839 24.2421 341.5 25.2212 341.5 26.2295V83.5928C341.5 84.4207 341.728 85.233 342.16 85.9395L346.193 92.5391C346.721 93.4025 347 94.3953 347 95.4072V200.788C347 202.337 346.347 203.815 345.2 204.857L342.973 206.882C342.035 207.735 341.5 208.944 341.5 210.212V230.288C341.5 231.556 342.035 232.765 342.973 233.618L345.2 235.643C346.347 236.685 347 238.163 347 239.712V301.957C347 303.397 346.435 304.78 345.426 305.809L322.327 329.352C321.293 330.406 319.878 331 318.401 331H312.018C310.853 331 309.733 331.452 308.895 332.261L283.876 356.385C282.996 357.233 282.5 358.403 282.5 359.625V368.462C282.5 369.899 281.937 371.279 280.933 372.307L240.328 413.845C239.293 414.903 237.876 415.5 236.396 415.5H114.539C113.102 415.5 111.721 414.937 110.693 413.932L68.1543 372.328C67.0964 371.293 66.5 369.876 66.5 368.396V359.65C66.4999 358.415 65.9917 357.234 65.0947 356.384L39.6025 332.233C38.7667 331.442 37.6591 331 36.5078 331H28.6279C27.1326 331 25.7009 330.391 24.6641 329.313L2.03711 305.799C1.05114 304.774 0.500079 303.407 0.5 301.985V239.842C0.500023 238.21 1.22461 236.661 2.47852 235.616L4.88086 233.615C5.90681 232.76 6.49998 231.494 6.5 230.158V210.342C6.49998 209.006 5.90681 207.74 4.88086 206.885L2.47852 204.884C1.22462 203.839 0.500023 202.29 0.5 200.658V78.5615C0.500073 77.4431 0.841025 76.3513 1.47754 75.4316L8.09766 65.8691C9.12497 64.3853 10.8154 63.5 12.6201 63.5H44.9053C46.1112 63.5 47.2674 63.0158 48.1133 62.1562L107.175 2.14258C108.209 1.09204 109.621 0.5 111.095 0.5H328.837Z';

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final data = await rootBundle.load('assets/images/Earth.jpg');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    setState(() {
      _image = frame.image;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) {
      return const SizedBox();
    }

    return Positioned(
      left: 32,
      top: 76,
      width: 295.5,
      height: 364,
      child: Stack(
        children: [
          // Relleno con imagen
          ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              final scaleX = bounds.width / _image!.width;
              final scaleY = bounds.height / _image!.height;
              final scale = scaleX > scaleY ? scaleX : scaleY;
              final matrix = Matrix4.identity()
                ..scale(scale, scale)
                ..translate(0.0, 0.0);
              return ImageShader(
                _image!,
                TileMode.clamp,
                TileMode.clamp,
                matrix.storage,
              );
            },
            child: SvgPicture.string(
              '<svg width="348" height="416" viewBox="0 0 348 416" xmlns="http://www.w3.org/2000/svg">'
              '<path d="$pathD" opacity="0.9" fill="white" />'
              '</svg>',
            ),
          ),
          // Stroke en gris encima
          SvgPicture.string(
            '<svg width="348" height="416" viewBox="0 0 348 416" xmlns="http://www.w3.org/2000/svg">'
            '<path d="$pathD" fill="none" stroke="#D9D9D9" stroke-width="1" />'
            '</svg>',
          ),
        ],
      ),
    );
  }
}