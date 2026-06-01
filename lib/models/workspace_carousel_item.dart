// lib/models/workspace_carousel_item.dart

import 'package:flutter/widgets.dart';

import '../widgets/workspace_filmstrip.dart';

class WorkspaceCarouselItem {
  final String title;
  final Widget thumbnail;
  final Widget page;

  const WorkspaceCarouselItem({
    required this.title,
    required this.thumbnail,
    required this.page,
  });

  WorkspaceFilmstripItem get filmstripItem {
    return WorkspaceFilmstripItem(title: title, thumbnail: thumbnail);
  }
}