import 'package:flutter/material.dart';

Widget MySearchBar(controller, callback) {
  return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(30),
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.only(top: 12), // TODO: This is a hardcoded value, fix before release
            hintText: "Search your files...",
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
          ),
          onSubmitted: (_) => callback(),
        ),
      ),
    );
}