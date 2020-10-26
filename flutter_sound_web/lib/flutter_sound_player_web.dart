/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 (LGPL-V3), as published by
 * the Free Software Foundation.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */

@JS()
library flutter_sound;

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data' show Uint8List;

import 'package:meta/meta.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_player_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:js/js.dart';


// ====================================  JS  =======================================================

@JS('newPlayerInstance')
external FlutterSoundPlayer newPlayerInstance(FlutterSoundPlayerCallback theCallBack);


@JS('FlutterSoundPlayer')
class FlutterSoundPlayer
{
        @JS('newInstance')
        external static FlutterSoundPlayer newInstance(FlutterSoundPlayerCallback theCallBack);

        @JS('playAudioFromURL')
        external int playAudioFromURL(String text);

        @JS('playAudioFromBuffer')
        external int playAudioFromBuffer(Uint8List buffer);

        @JS('releaseMediaPlayer')
        external int releaseMediaPlayer();

        @JS('initializeMediaPlayer')
        external int initializeMediaPlayer(FlutterSoundPlayerCallback callback, int focus, int category, int mode, int audioFlags, int device, bool withUI);

        @JS('setAudioFocus')
        external int setAudioFocus(int focus, int category, int mode, int audioFlags, int device,);

        @JS('getPlayerState')
        external int getPlayerState();

        @JS('isDecoderSupported')
        external bool isDecoderSupported( int codec,);

        @JS('setSubscriptionDuration')
        external int setSubscriptionDuration( int duration);

        @JS('startPlayer')
        external int startPlayer(int codec, Uint8List fromDataBuffer, String  fromURI, int numChannels, int sampleRate);

        @JS('feed')
        external int feed(Uint8List data,);

        @JS('startPlayerFromTrack')
        external int startPlayerFromTrack(int progress, int duration, Map<String, dynamic> track, bool canPause, bool canSkipForward, bool canSkipBackward, bool defaultPauseResume, bool removeUIWhenStopped, );

        @JS('nowPlaying')
        external int nowPlaying(int progress, int duration, Map<String, dynamic> track, bool canPause, bool canSkipForward, bool canSkipBackward, bool defaultPauseResume, );

        @JS('stopPlayer')
        external int stopPlayer();

        @JS('resumePlayer')
        external int pausePlayer();

        @JS('')
        external int resumePlayer();

        @JS('seekToPlayer')
        external int seekToPlayer( int duration);

        @JS('setVolume')
        external int setVolume(double volume);

        @JS('setUIProgressBar')
        external int setUIProgressBar(int duration, int progress);
}

//=========================================================================================================


/// The web implementation of [FlutterSoundPlatform].
///
/// This class implements the `package:flutter_sound_player` functionality for the web.
///

class FlutterSoundPlayerWeb extends FlutterSoundPlayerPlatform //implements FlutterSoundPlayerCallback
{


        static List<String> defaultExtensions  =
        [
                "flutter_sound.aac", // defaultCodec
                "flutter_sound.aac", // aacADTS
                "flutter_sound.opus", // opusOGG
                "flutter_sound_opus.caf", // opusCAF
                "flutter_sound.mp3", // mp3
                "flutter_sound.ogg", // vorbisOGG
                "flutter_sound.pcm", // pcm16
                "flutter_sound.wav", // pcm16WAV
                "flutter_sound.aiff", // pcm16AIFF
                "flutter_sound_pcm.caf", // pcm16CAF
                "flutter_sound.flac", // flac
                "flutter_sound.mp4", // aacMP4
                "flutter_sound.amr", // amrNB
                "flutter_sound.amr", // amrWB
                "flutter_sound.pcm", // pcm8
                "flutter_sound.pcm", // pcmFloat32
        ];



        /// Registers this class as the default instance of [FlutterSoundPlatform].
        static void registerWith(Registrar registrar)
        {
                FlutterSoundPlayerPlatform.instance = FlutterSoundPlayerWeb();
        }


        /* ctor */ MethodChannelFlutterSoundPlayer()
        {
        }


//============================================ Session manager ===================================================================


        List<FlutterSoundPlayer> _slots = [];
        FlutterSoundPlayer getWebSession(FlutterSoundPlayerCallback callback)
        {
                return _slots[findSession(callback)];
        }



//==============================================================================================================================

        @override
        Future<int> initializeMediaPlayer(FlutterSoundPlayerCallback callback, {AudioFocus focus, SessionCategory category, SessionMode mode, int audioFlags, AudioDevice device, bool withUI}) async
        {
                // openAudioSessionCompleter = new Completer<bool>();
                // await invokeMethod( callback, 'initializeMediaPlayer', {'focus': focus.index, 'category': category.index, 'mode': mode.index, 'audioFlags': audioFlags, 'device': device.index, 'withUI': withUI ? 1 : 0 ,},) ;
                // return  openAudioSessionCompleter.future ;
                int slotno = findSession(callback);
                if (slotno < _slots.length)
                {
                        assert (_slots[slotno] == null);
                        _slots[slotno] = newPlayerInstance(callback);
                } else
                {
                        assert(slotno == _slots.length);
                        _slots.add( newPlayerInstance(callback));
                }
                return _slots[slotno].initializeMediaPlayer( callback, focus.index,  category.index, mode.index, audioFlags, device.index, withUI);
        }


        @override
        Future<int> releaseMediaPlayer(FlutterSoundPlayerCallback callback, ) async
        {
                int slotno = findSession(callback);
                int r = _slots[slotno].releaseMediaPlayer();
                _slots[slotno] = null;
                return r;
        }

        @override
        Future<int> setAudioFocus(FlutterSoundPlayerCallback callback, {AudioFocus focus, SessionCategory category, SessionMode mode, int audioFlags, AudioDevice device,} ) async
        {
                return getWebSession(callback).setAudioFocus(focus.index, category.index, mode.index, audioFlags, device.index);
        }


        @override
        Future<int> getPlayerState(FlutterSoundPlayerCallback callback, ) async
        {
                return getWebSession(callback).getPlayerState();
        }
        @override
        Future<Map<String, Duration>> getProgress(FlutterSoundPlayerCallback callback, ) async
        {
                // Map<String, int> m = await invokeMethod( callback, 'getPlayerState', null,) as Map;
                // Map<String, Duration> r = {'duration': Duration(milliseconds: m['duration']), 'progress': Duration(milliseconds: m['progress']),};
                // return r;
                return null;
        }

        @override
        Future<bool> isDecoderSupported(FlutterSoundPlayerCallback callback, { Codec codec,}) async
        {
                return getWebSession(callback).isDecoderSupported(codec.index);
        }


        @override
        Future<int> setSubscriptionDuration(FlutterSoundPlayerCallback callback, { Duration duration,}) async
        {
                return getWebSession(callback).setSubscriptionDuration(duration.inMilliseconds);
        }

        @override
        Future<int> startPlayer(FlutterSoundPlayerCallback callback,  {Codec codec, Uint8List fromDataBuffer, String  fromURI, int numChannels, int sampleRate}) async
        {
                // startPlayerCompleter = new Completer<Map>();
                // await invokeMethod( callback, 'startPlayer', {'codec': codec.index, 'fromDataBuffer': fromDataBuffer, 'fromURI': fromURI, 'numChannels': numChannels, 'sampleRate': sampleRate},) ;
                // return  startPlayerCompleter.future ;
                // String s = "https://file-examples-com.github.io/uploads/2017/11/file_example_MP3_700KB.mp3";
                if (codec == null)
                        codec = Codec.defaultCodec;
                if (fromDataBuffer != null)
                {
                        if (fromURI != null)
                        {
                                throw Exception("You may not specify both 'fromURI' and 'fromDataBuffer' parameters");
                        }
                        //js.context.callMethod('playAudioFromBuffer', [fromDataBuffer]);
                        //playAudioFromBuffer(fromDataBuffer);
                        return getWebSession(callback).playAudioFromBuffer(fromDataBuffer);
                        //playAudioFromBuffer3(fromDataBuffer);
                        //Directory tempDir = await getTemporaryDirectory();
                        /*
                        String path = defaultExtensions[codec.index];
                        File filOut = File(path);
                        IOSink sink = filOut.openWrite();
                        sink.add(fromDataBuffer.toList());
                        fromURI = path;
                         */
                }
                //js.context.callMethod('playAudioFromURL', [fromURI]);
                getWebSession(callback).playAudioFromURL(fromURI);
                return 0;
        }

        @override
        Future<int> feed(FlutterSoundPlayerCallback callback, {Uint8List data, }) async
        {
                return getWebSession(callback).feed(data);
        }

        @override
        Future<int> startPlayerFromTrack(FlutterSoundPlayerCallback callback, {Duration progress, Duration duration, Map<String, dynamic> track, bool canPause, bool canSkipForward, bool canSkipBackward, bool defaultPauseResume, bool removeUIWhenStopped }) async
        {
                // startPlayerCompleter = new Completer<Map>();
                // await invokeMethod( callback, 'startPlayerFromTrack', {'progress': progress, 'duration': duration, 'track': track, 'canPause': canPause, 'canSkipForward': canSkipForward, 'canSkipBackward': canSkipBackward,
                //   'defaultPauseResume': defaultPauseResume, 'removeUIWhenStopped': removeUIWhenStopped,},);
                // return  startPlayerCompleter.future ;
                //
                return getWebSession(callback).startPlayerFromTrack( progress.inMilliseconds,  duration.inMilliseconds, track, canPause, canSkipForward, canSkipBackward, defaultPauseResume, removeUIWhenStopped);
          }

        @override
        Future<int> nowPlaying(FlutterSoundPlayerCallback callback,  {Duration progress, Duration duration, Map<String, dynamic> track, bool canPause, bool canSkipForward, bool canSkipBackward, bool defaultPauseResume, }) async
        {
                return getWebSession(callback).nowPlaying(progress.inMilliseconds, duration.inMilliseconds, track, canPause, canSkipForward, canSkipBackward, defaultPauseResume);
        }

        @override
        Future<int> stopPlayer(FlutterSoundPlayerCallback callback,  ) async
        {
                return getWebSession(callback).stopPlayer();
        }

        @override
        Future<int> pausePlayer(FlutterSoundPlayerCallback callback,  ) async
        {
                return getWebSession(callback).pausePlayer();
        }

        @override
        Future<int> resumePlayer(FlutterSoundPlayerCallback callback,  ) async
        {
                return getWebSession(callback).resumePlayer();
        }

        @override
        Future<int> seekToPlayer(FlutterSoundPlayerCallback callback,  {Duration duration}) async
        {
                return getWebSession(callback).seekToPlayer(duration.inMilliseconds);
        }

        Future<int> setVolume(FlutterSoundPlayerCallback callback,  {double volume}) async
        {
                return getWebSession(callback).setVolume(volume);
        }

        @override
        Future<int> setUIProgressBar(FlutterSoundPlayerCallback callback, {Duration duration, Duration progress,}) async
        {
                return getWebSession(callback).setUIProgressBar(duration.inMilliseconds, progress.inMilliseconds);
        }

        Future<String> getResourcePath(FlutterSoundPlayerCallback callback, ) async
        {
                return null;
        }

 }
