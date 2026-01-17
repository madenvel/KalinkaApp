import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalinka/data_model/playqueue_events.dart';
import 'package:kalinka/data_model/data_model.dart';

void main() {
  group('PlayQueue snapshot + events (provided stream)', () {
    // Provided JSON lines
    const replaySnapshot =
        '{"event_type":"replay_event","state_type":"PlayQueueState","state":{"playback_state":{"state":"PLAYING","current_track":{"id":"kalinka:localfiles:track:track_9f81eda6db30c2b5","title":"Theme from Antarctica","duration":450,"performer":{"id":"kalinka:localfiles:artist:artist_2c4008bd20918d21","name":"Vangelis","image":null,"album_count":null},"album":{"id":"kalinka:localfiles:album:album_4a9379e0d05abd16","title":"The Best of Vangelis CD II","duration":null,"track_count":null,"image":{"small":"/resource/album/album_4a9379e0d05abd16_small.jpg","thumbnail":"/resource/album/album_4a9379e0d05abd16_thumbnail.jpg","large":"/resource/album/album_4a9379e0d05abd16_large.jpg"},"label":null,"genre":null,"artist":{"id":"kalinka:localfiles:artist:artist_2c4008bd20918d21","name":"Vangelis","image":null,"album_count":null}},"replaygain_peak":null,"replaygain_gain":null,"playlist_track_id":null},"index":0,"position":0,"message":null,"audio_info":{"sample_rate":44100,"bits_per_sample":16,"channels":2,"duration_ms":450000},"mime_type":"audio/flac","timestamp":20813571921032},"track_list":[{"id":"kalinka:localfiles:track:track_9f81eda6db30c2b5","title":"Theme from Antarctica","duration":450,"performer":{"id":"kalinka:localfiles:artist:artist_2c4008bd20918d21","name":"Vangelis","image":null,"album_count":null},"album":{"id":"kalinka:localfiles:album:album_4a9379e0d05abd16","title":"The Best of Vangelis CD II","duration":null,"track_count":null,"image":{"small":"/resource/album/album_4a9379e0d05abd16_small.jpg","thumbnail":"/resource/album/album_4a9379e0d05abd16_thumbnail.jpg","large":"/resource/album/album_4a9379e0d05abd16_large.jpg"},"label":null,"genre":null,"artist":{"id":"kalinka:localfiles:artist:artist_2c4008bd20918d21","name":"Vangelis","image":null,"album_count":null}},"replaygain_peak":null,"replaygain_gain":null,"playlist_track_id":null},{"id":"kalinka:localfiles:track:track_318d2552937973b1","title":"Mouettes","duration":149,"performer":{"id":"kalinka:localfiles:artist:artist_2c4008bd20918d21","name":"Vangelis","image":null,"album_count":null},"album":{"id":"kalinka:localfiles:album:album_4a9379e0d05abd16","title":"The Best of Vangelis CD II","duration":null,"track_count":null,"image":{"small":"/resource/album/album_4a9379e0d05abd16_small.jpg","thumbnail":"/resource/album/album_4a9379e0d05abd16_thumbnail.jpg","large":"/resource/album/album_4a9379e0d05abd16_large.jpg"},"label":null,"genre":null,"artist":{"id":"kalinka:localfiles:artist:artist_2c4008bd20918d21","name":"Vangelis","image":null,"album_count":null}},"replaygain_peak":null,"replaygain_gain":null,"playlist_track_id":null}],"playback_mode":{"shuffle":false,"repeat_single":false,"repeat_all":false},"seq":7},"seq":0}';
    const tracksAdded =
        '{"event_type":"tracks_added","seq":1,"tracks":[{"id":"kalinka:localfiles:track:track_b5af0c9909e0d37b","title":"Memories of green","duration":334,"performer":{"id":"kalinka:localfiles:artist:artist_2c4008bd20918d21","name":"Vangelis","image":null,"album_count":null},"album":{"id":"kalinka:localfiles:album:album_4a9379e0d05abd16","title":"The Best of Vangelis CD II","duration":null,"track_count":null,"image":{"small":"/resource/album/album_4a9379e0d05abd16_small.jpg","thumbnail":"/resource/album/album_4a9379e0d05abd16_thumbnail.jpg","large":"/resource/album/album_4a9379e0d05abd16_large.jpg"},"label":null,"genre":null,"artist":{"id":"kalinka:localfiles:artist:artist_2c4008bd20918d21","name":"Vangelis","image":null,"album_count":null}},"replaygain_peak":null,"replaygain_gain":null,"playlist_track_id":null}]}';
    const tracksRemovedFromSnapshot =
        '{"event_type":"tracks_removed","seq":2,"indices":[0]}';
    const playbackModeChangedEvent =
        '{"event_type":"playback_mode_changed","seq":3,"mode":{"shuffle":true,"repeat_single":true,"repeat_all":false}}';

    test('replay_event snapshot decoded as PlayQueueState', () {
      final json = jsonDecode(replaySnapshot) as Map<String, dynamic>;
      expect(json['event_type'], equals('replay_event'));
      expect(json['state_type'], equals('PlayQueueState'));

      final snapshot = PlayQueueState.fromJson(json['state']);
      expect(snapshot.seq, equals(7));
      expect(snapshot.playbackState.state, equals(PlayerStateType.playing));
      expect(snapshot.playbackState.mimeType, equals('audio/flac'));
      expect(snapshot.playbackState.audioInfo, isNotNull);
      expect(snapshot.playbackState.audioInfo!.sampleRate, equals(44100));
      expect(snapshot.playbackState.audioInfo!.durationMs, equals(450000));
      expect(
        snapshot.playbackState.currentTrack!.title,
        equals('Theme from Antarctica'),
      );
      expect(snapshot.trackList.length, equals(2));
      expect(snapshot.trackList.first.title, equals('Theme from Antarctica'));
      expect(snapshot.trackList[1].title, equals('Mouettes'));
      expect(snapshot.playbackMode.shuffle, isFalse);
      expect(snapshot.playbackMode.repeatSingle, isFalse);
      expect(snapshot.playbackMode.repeatAll, isFalse);
    });

    test('PlayQueueEvent.fromJson parses replay_event snapshot', () {
      final json = jsonDecode(replaySnapshot) as Map<String, dynamic>;
      final event = PlayQueueEvent.fromJson(json);
      expect(event, isA<ReplayPlayQueueEvent>());
      final replay = event as ReplayPlayQueueEvent;
      expect(replay.seq, equals(0));
      expect(replay.state.playbackState.state, equals(PlayerStateType.playing));
      expect(replay.state.trackList.length, equals(2));
    });

    test('apply tracks_added onto snapshot', () {
      final snapshotJson = jsonDecode(replaySnapshot) as Map<String, dynamic>;
      var state = PlayQueueState.fromJson(snapshotJson['state']);

      // tracks_added
      final addedEvent = PlayQueueEvent.fromJson(
        jsonDecode(tracksAdded) as Map<String, dynamic>,
      );
      state = state.apply(addedEvent, 12345);
      expect(state.seq, equals(1));
      expect(state.trackList.length, equals(3));
      expect(state.trackList[2].title, equals('Memories of green'));
    });

    test('apply tracks_removed onto snapshot', () {
      final snapshotJson = jsonDecode(replaySnapshot) as Map<String, dynamic>;
      var state = PlayQueueState.fromJson(snapshotJson['state']);

      // Remove first track; expect remaining is 'Mouettes'
      final removedEvent = PlayQueueEvent.fromJson(
        jsonDecode(tracksRemovedFromSnapshot) as Map<String, dynamic>,
      );
      state = state.apply(removedEvent, 12345);
      expect(state.seq, equals(2));
      expect(state.trackList.length, equals(1));
      expect(state.trackList.first.title, equals('Mouettes'));
    });

    test('apply playback_mode_changed onto snapshot', () {
      final snapshotJson = jsonDecode(replaySnapshot) as Map<String, dynamic>;
      var state = PlayQueueState.fromJson(snapshotJson['state']);

      final modeEvent = PlayQueueEvent.fromJson(
        jsonDecode(playbackModeChangedEvent) as Map<String, dynamic>,
      );
      state = state.apply(modeEvent, 12345);
      expect(state.seq, equals(3));
      expect(state.playbackMode.shuffle, isTrue);
      expect(state.playbackMode.repeatSingle, isTrue);
      expect(state.playbackMode.repeatAll, isFalse);
    });
  });
}
