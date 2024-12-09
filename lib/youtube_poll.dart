library;

import 'dart:async';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Duration _5mins() => Duration(minutes: 5);

class YoutubePoll {
  final YoutubeExplode yt;
  final _ignored = <String>{};

  YoutubePoll([YoutubeExplode? yt]) : yt = yt ?? YoutubeExplode();

  /// Polls [channel] for new videos once.
  Stream<Video> pollOnce(channel) async* {
    final vids = await yt.channels
        .getUploads(channel)
        .map((v) => v.id)
        .where((v) => !_ignored.contains(v.value))
        .toList();
    yield* Stream.fromIterable(vids).asyncMap((v) => yt.videos.get(v));
    _ignored.addAll(vids.map((v) => v.value));
  }

  /// Polls [channel] for new videos every [interval].
  Stream<List<Video>> pollBatched(channel, [Duration Function() interval = _5mins]) async* {
    yield await pollOnce(channel).toList();
    final i = interval();
    if (i.inSeconds > 0) {
      yield* await Future.delayed(i, () => pollBatched(channel));
    }
  }

  // Polls [channel] for new videos every [interval] and returns them individually.
  Stream<Video> poll(channel, [Duration Function() interval = _5mins]) async* {
    yield* pollOnce(channel);
    final i = interval();
    if (i.inSeconds > 0) {
      yield* await Future.delayed(i, () => poll(channel));
    }
  }

  /// Ignores all videos currently published by [channel].
  Future<void> ignoreOld(channel) async => _ignored.addAll(
      await yt.channels.getUploads(channel).map((v) => v.id.value).toList());
}
