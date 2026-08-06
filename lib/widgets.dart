import 'package:exif_authority_elite/variables.dart';
import 'package:flutter/material.dart';

AppBar appBar({
  List<Widget>? actions,
}){
  return AppBar(
    centerTitle: true,
    title: const Text(
      "Exif Authority Elite",
      style: TextStyle(
        color: logoForegroundColor,
        fontFamily: fontName,
      ),
    ),
    backgroundColor: logoBackgroundColor,
    foregroundColor: logoForegroundColor,
    actions: actions,
  );
}
class EliteButton extends StatelessWidget {
  const EliteButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
  });
  final String text;
  final IconData icon;
  final Function onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        onTap();
      },
      child: Container(
        color: logoBackgroundColor,
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: logoForegroundColor,
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: logoForegroundColor,
                  fontSize: 15,
                  fontFamily: fontName,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(logoForegroundColor),
      ),
    );
  }
}