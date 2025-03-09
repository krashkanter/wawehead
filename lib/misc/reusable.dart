import "package:flutter/material.dart";

Widget textFieldCustom(TextEditingController tf) {
  return SizedBox(
    width: double.infinity,
    child: TextField(
      controller: tf,
      cursorWidth: 10,
      maxLines: 5,
      autofocus: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black,
        border: InputBorder.none
      ),
      style: const TextStyle(color: Colors.white),
    ),
  );
}

Widget elevatedButtonCustom() {
  return SizedBox(
    width: double.infinity, // Match TextField width
    child: ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black, // Match TextField color
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero), // Remove border radius
      ),
      child: const Icon(Icons.check, color: Colors.white),
    ),
  );
}
