/*
 * Copyright 2017-2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *     http://aws.amazon.com/apache2.0/
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#ifndef AACE_ALEXA_ALEXA_ENGINE_INTERFACES_H
#define AACE_ALEXA_ALEXA_ENGINE_INTERFACES_H

#include <fstream>
#include <iostream>
#include <string>
#include <vector>
#include <memory>
#include <limits>

/** @file */

#pragma push_macro("NO_ERROR")
#ifdef NO_ERROR
#undef NO_ERROR
#endif

namespace aace {
namespace alexa {

/**
 * MediaPlayerEngineInterface
 */
class MediaPlayerEngineInterface {
public:

    /**
     * Describes an error during a media playback operation
     */
    enum class MediaError {

        /**
         * An unknown error occurred.
         */
        MEDIA_ERROR_UNKNOWN,

        /**
         * The server recognized the request as malformed (e.g. bad request, unauthorized, forbidden, not found, etc).
         */
        MEDIA_ERROR_INVALID_REQUEST,

        /**
         * The client was unable to reach the service.
         */
        MEDIA_ERROR_SERVICE_UNAVAILABLE,

        /**
         * The server accepted the request but was unable to process it as expected.
         */
        MEDIA_ERROR_INTERNAL_SERVER_ERROR,

        /**
         * There was an internal error on the client.
         */
        MEDIA_ERROR_INTERNAL_DEVICE_ERROR
    };
    
    /**
     * Describes the playback state of the platform media player
     */
    enum class MediaState {

        /**
         * The media player is not currently playing. It may have paused, stopped, or finished.
         */
        STOPPED,

        /**
         * The media player is currently playing.
         */
        PLAYING,

        /**
         * The media player is currently buffering data.
         */
        BUFFERING,

        PAUSED,

        FINISHED,

        ERROR
    };
    
    virtual void onMediaStateChanged( MediaState state ) = 0;
    virtual void onMediaError( MediaError error, const std::string& description ) = 0;
    virtual ssize_t read( char* data, const size_t size ) = 0;
    virtual bool isRepeating() = 0;
    virtual bool isClosed() = 0;
};

inline std::ostream& operator<<(std::ostream& stream, const MediaPlayerEngineInterface::MediaState& state) {
    switch (state) {
        case MediaPlayerEngineInterface::MediaState::STOPPED:
            stream << "STOPPED";
            break;
        case MediaPlayerEngineInterface::MediaState::PLAYING:
            stream << "PLAYING";
            break;
        case MediaPlayerEngineInterface::MediaState::BUFFERING:
            stream << "BUFFERING";
            break;
        case MediaPlayerEngineInterface::MediaState::PAUSED:
            stream << "PAUSED";
            break;
        case MediaPlayerEngineInterface::MediaState::FINISHED:
            stream << "FINISHED";
            break;
        case MediaPlayerEngineInterface::MediaState::ERROR:
            stream << "ERROR";
            break;
    }
    return stream;
}

inline std::ostream& operator<<(std::ostream& stream, const MediaPlayerEngineInterface::MediaError& error) {
    switch (error) {
        case MediaPlayerEngineInterface::MediaError::MEDIA_ERROR_UNKNOWN:
            stream << "MEDIA_ERROR_UNKNOWN";
            break;
        case MediaPlayerEngineInterface::MediaError::MEDIA_ERROR_INVALID_REQUEST:
            stream << "MEDIA_ERROR_INVALID_REQUEST";
            break;
        case MediaPlayerEngineInterface::MediaError::MEDIA_ERROR_SERVICE_UNAVAILABLE:
            stream << "MEDIA_ERROR_SERVICE_UNAVAILABLE";
            break;
        case MediaPlayerEngineInterface::MediaError::MEDIA_ERROR_INTERNAL_SERVER_ERROR:
            stream << "MEDIA_ERROR_INTERNAL_SERVER_ERROR";
            break;
        case MediaPlayerEngineInterface::MediaError::MEDIA_ERROR_INTERNAL_DEVICE_ERROR:
            stream << "MEDIA_ERROR_INTERNAL_DEVICE_ERROR";
            break;
    }
    return stream;
}

/**
 * SpeakerEngineInterface
 */
class SpeakerEngineInterface {
public:
    virtual void onLocalVolumeSet( int8_t volume ) = 0;
    virtual void onLocalMuteSet( bool mute ) = 0;
};

/**
 * SpeechRecognizerEngineInterface
 */
class SpeechRecognizerEngineInterface {
public:
    /**
     * Describes type of event that initiated the speech request.
     */
    enum class Initiator {
    
        /**
         * Hold-to-talk speech initiator type.
         */
        HOLD_TO_TALK,
        /**
         * Tap-to-talk speech initiator type.
         */
        TAP_TO_TALK,
        /**
         * Wakeword speech initiator type.
         */
        WAKEWORD
    };
    
    /*
     * Defines an unspecified value for the speech recognizer's audio index.
     */
    static constexpr uint64_t UNSPECIFIED_INDEX = std::numeric_limits<uint64_t>::max();

    virtual bool onStartCapture( Initiator initiator, uint64_t keywordBegin, uint64_t keywordEnd, const std::string& keyword ) = 0;
    virtual bool onStopCapture() = 0;
    virtual ssize_t write( const int16_t* data, const size_t size ) = 0;
    virtual bool enableWakewordDetection() = 0;
    virtual bool disableWakewordDetection() = 0;
    virtual std::string getCurrentDialogRequestId() = 0;
    virtual std::string getMessageRequestStatus() = 0;
    virtual bool ClearDirectiveProcessId() = 0;
};

inline std::ostream& operator<<(std::ostream& stream, const SpeechRecognizerEngineInterface::Initiator& initiator) {
    switch (initiator) {
        case SpeechRecognizerEngineInterface::Initiator::HOLD_TO_TALK:
            stream << "HOLD_TO_TALK";
            break;
        case SpeechRecognizerEngineInterface::Initiator::TAP_TO_TALK:
            stream << "TAP_TO_TALK";
            break;
        case SpeechRecognizerEngineInterface::Initiator::WAKEWORD:
            stream << "WAKEWORD";
            break;
    }
    return stream;
}

/**
 * AlertsEngineInterface
 */
class AlertsEngineInterface {
public:
    virtual void onLocalStop() = 0;

    virtual void removeAllAlerts() = 0;

    virtual void onRemoveAlert(const std::string & alertToken) = 0;
};

/**
 * PlaybackControllerEngineInterface
 */
class PlaybackControllerEngineInterface {
public:
    /**
     * Describes the playback button type
     */
    enum class PlaybackButton {
        /**
         * 'Play' button.
         */
        PLAY,
        /**
         * 'Pause' button.
         */
        PAUSE,
        /**
         * 'Next' button.
         */
        NEXT,
        /**
         * 'Previous' button.
         */
        PREVIOUS,
        /**
         * 'Skip Forward' button.
         */
        SKIP_FORWARD,
        /**
         * 'Skip Backward' button.
         */
        SKIP_BACKWARD,
        /**
         * 'Exit' button.
         */
        EXIT
    };

    /**
     * Describes the playback button type
     */
    enum class PlaybackToggle {
        /**
         * 'Shuffle' toggle.
         */
        SHUFFLE,
        /**
         * 'Loop' toggle.
         */
        LOOP,
        /**
         * 'Repeat' toggle.
         */
        REPEAT,
        /**
         * 'Thumbs Up' toggle.
         */
        THUMBS_UP,
        /**
         * 'Thumbs Down' toggle.
         */
        THUMBS_DOWN
    };

    virtual void onButtonPressed(PlaybackButton button) = 0;
    virtual void onTogglePressed(PlaybackToggle toggle, bool action) = 0;
};

/**
 * AuthProviderEngineInterface
 */
class AuthProviderEngineInterface {
public:
    /**
     * Describes the state of client authorization with AVS
     */
    enum class AuthState {

        /**
         * Authorization has not yet been acquired.
         */
        UNINITIALIZED,

        /**
         * Authorization has been refreshed.
         */
        REFRESHED,

        /**
         * Authorization has expired.
         */
        EXPIRED,

        /**
         * Authorization has failed in a manner that cannot be corrected by retrying.
         */
        UNRECOVERABLE_ERROR
    };

    /**
     * Describes an error during an attempt to authorize with AVS
     */
    enum class AuthError {

        /**
         * No error encountered
         */
        NO_ERROR,

        /**
         * An error was encountered, but no error description can be determined.
         */
        UNKNOWN_ERROR,

        /**
         * The client authorization failed.
         */
        AUTHORIZATION_FAILED,

        /**
         * The client is not authorized to use authorization codes.
         */
        UNAUTHORIZED_CLIENT,

        /**
         * The server encountered a runtime error.
         */
        SERVER_ERROR,

        /**
         * The request is missing a required parameter, has an invalid value, or is otherwise malformed.
         */
        INVALID_REQUEST,

        /**
         * One of the values in the request was invalid.
         */
        INVALID_VALUE,

        /**
         * The authorization code is invalid, expired, revoked, or was issued to a different client.
         */
        AUTHORIZATION_EXPIRED,

        /**
         * The client specified the wrong token type.
         */
        UNSUPPORTED_GRANT_TYPE,
        
        /**
         * Invalid code pair provided in Code-based linking token request.
         */
        INVALID_CODE_PAIR,
        
        /**
         * Waiting for user to authorize the specified code pair.
         */
        AUTHORIZATION_PENDING,
        
        /**
         * Client should slow down in the rate of requests polling for an access token.
         */
        SLOW_DOWN,
        
        /**
         * Internal error in client code.
         */
        INTERNAL_ERROR,
        
        /**
         * Client ID not valid for use with code based linking.
         */
        INVALID_CBL_CLIENT_ID
    };

    virtual void onAuthStateChanged( AuthState state, AuthError error ) = 0;
};

inline std::ostream& operator<<(std::ostream& stream, const AuthProviderEngineInterface::AuthState& state) {
    switch (state) {
        case AuthProviderEngineInterface::AuthState::UNINITIALIZED:
            stream << "UNINITIALIZED";
            break;
        case AuthProviderEngineInterface::AuthState::REFRESHED:
            stream << "REFRESHED";
            break;
        case AuthProviderEngineInterface::AuthState::EXPIRED:
            stream << "EXPIRED";
            break;
        case AuthProviderEngineInterface::AuthState::UNRECOVERABLE_ERROR:
            stream << "UNRECOVERABLE_ERROR";
            break;
    }
    return stream;
}

inline std::ostream& operator<<(std::ostream& stream, const AuthProviderEngineInterface::AuthError& error) {
    switch (error) {
        case AuthProviderEngineInterface::AuthError::NO_ERROR:
            stream << "NO_ERROR";
            break;
        case AuthProviderEngineInterface::AuthError::UNKNOWN_ERROR:
            stream << "UNKNOWN_ERROR";
            break;
        case AuthProviderEngineInterface::AuthError::AUTHORIZATION_FAILED:
            stream << "AUTHORIZATION_FAILED";
            break;
        case AuthProviderEngineInterface::AuthError::UNAUTHORIZED_CLIENT:
            stream << "UNAUTHORIZED_CLIENT";
            break;
        case AuthProviderEngineInterface::AuthError::SERVER_ERROR:
            stream << "SERVER_ERROR";
            break;
        case AuthProviderEngineInterface::AuthError::INVALID_REQUEST:
            stream << "INVALID_REQUEST";
            break;
        case AuthProviderEngineInterface::AuthError::INVALID_VALUE:
            stream << "INVALID_VALUE";
            break;
        case AuthProviderEngineInterface::AuthError::AUTHORIZATION_EXPIRED:
            stream << "AUTHORIZATION_EXPIRED";
            break;
        case AuthProviderEngineInterface::AuthError::UNSUPPORTED_GRANT_TYPE:
            stream << "UNSUPPORTED_GRANT_TYPE";
            break;
        case AuthProviderEngineInterface::AuthError::INVALID_CODE_PAIR:
            stream << "INVALID_CODE_PAIR";
            break;
        case AuthProviderEngineInterface::AuthError::AUTHORIZATION_PENDING:
            stream << "AUTHORIZATION_PENDING";
            break;
        case AuthProviderEngineInterface::AuthError::SLOW_DOWN:
            stream << "SLOW_DOWN";
            break;
        case AuthProviderEngineInterface::AuthError::INTERNAL_ERROR:
            stream << "INTERNAL_ERROR";
            break;
        case AuthProviderEngineInterface::AuthError::INVALID_CBL_CLIENT_ID:
            stream << "INVALID_CBL_CLIENT_ID";
            break;
    }
    return stream;
}
 
/**
 * ExternalMediaAdapterEngineInterface
 */
class ExternalMediaAdapterEngineInterface {
public:
    /**
     * Describes a discovered external media player app
     */
    class DiscoveredPlayerInfo {
    public:
        /// The opaque token that uniquely identifies the local external player app
        std::string localPlayerId;
        /// The only spiVersion that currently exists is "1.0"
        std::string spiVersion;
        /** Validation methods :
         *  1. "SIGNING_CERTIFICATE"
         *  2. "GENERATED_CERTIFICATE"
         *  3. "NONE"
         */
        std::string validationMethod;
        /** Validation data :
         *  1. Device platform issued app signing certificate. A list of certificates may be attached.
         *  2. In some cases validation is performed locally. The certificate is trasmitted as validationData during discovery to announce the activated app's identity in order to allow app activation to be revoked.
         *  3. empty
         */
        std::vector<std::string> validationData;
    };
    
    virtual void onReportDiscoveredPlayers( const std::vector<DiscoveredPlayerInfo>& discoveredPlayers ) = 0;
    virtual void onRequestToken( const std::string& localPlayerId ) = 0;
    virtual void onLoginComplete( const std::string& localPlayerId ) = 0;
    virtual void onLogoutComplete( const std::string& localPlayerId ) = 0;
    virtual void onPlayerEvent( const std::string& localPlayerId, const std::string& eventName ) = 0;
    virtual void onPlayerError( const std::string& localPlayerId, const std::string& errorName, long code, const std::string& description, bool fatal ) = 0;
    virtual void onSetFocus( const std::string& playerId ) = 0;
    virtual void onRemoveDiscoveredPlayer( const std::string& localPlayerId ) = 0;
};

/**
 * LocalMediaSourceEngineInterface
 */
class LocalMediaSourceEngineInterface {
public:
    virtual void onPlayerEvent( const std::string& eventName ) = 0;
    virtual void onPlayerError( const std::string& errorName, long code, const std::string& description, bool fatal ) = 0;
    virtual void onSetFocus() = 0;
};

/**
 * EqualizerControllerEngineInterface
 */
class EqualizerControllerEngineInterface {
public:

    /**
     * Describes the equalizer bands supported by Alexa. The platform implementation may support a subset of these.
     */
    enum class EqualizerBand {
        /// Bass equalizer band
        BASS,
        /// Mid-range equalizer band
        MIDRANGE,
        /// Treble equalizer band
        TREBLE
    };

    /**
     * Describes the level of gain of a particular equalizer band as an integer dB value. This is an
     * @c aace::alexa::EqualizerController::EqualizerBand and @c int pair.
     */ 
    using EqualizerBandLevel = std::pair<EqualizerBand,int>;

    /**
     * @internal
     * Notifies the Engine that gain levels for one or more equalizer bands are being set directly on the device. If 
     * unsupported levels are provided, the Engine should truncate the settings to the configured range.
     * 
     * @param [in] bandLevels The equalizer bands to change and their gain settings as integer dB values.
     */
    virtual void onLocalSetBandLevels( const std::vector<EqualizerBandLevel>& bandLevels ) = 0;

    /**
     * @internal
     * Notifies the Engine that relative adjustments to equalizer band gain levels are being made directly on the 
     * device. If adjustments put the band level settings beyond the configured dB range, the Engine should truncate 
     * the settings to the configured range.
     * 
     * @param [in] bandAdjustments The equalizer bands to adjust and their relative gain adjustments as integer dB 
     *             values.
     */
    virtual void onLocalAdjustBandLevels( const std::vector<EqualizerBandLevel>& bandAdjustments ) = 0;

    /**
     * @internal
     * Notifies the Engine that the gain levels for the equalizer bands are being reset to their defaults.
     * 
     * @param [in] bands The equalizer bands to reset. Empty @a bands resets all supported equalizer bands.
     */
    virtual void onLocalResetBands( const std::vector<EqualizerBand>& bands ) = 0;
};

/**
 *  AzeroExpressEngineInterface
 */
class AzeroExpressEngineInterface {
public:
    virtual void sendEvent(const std::string& jsonContent) = 0;
    virtual void reconnectAVSnet() = 0;
    virtual void disconnectAVSnet() = 0;
    virtual void connectAVSnet() = 0;
};

/**
 *  AzeroACMEngineInterface
 */
class AzeroACMEngineInterface {
public:
    virtual void sendEvent(const std::string& jsonContent) = 0;
};

/**
 *  BluetoothEngineInterface
 */
class BluetoothEngineInterface {
public:
    virtual bool setDeviceManager(void) = 0;
};

/**
 *  AzeroBluetoothEngineInterface
 */
class AzeroBluetoothEngineInterface {
public:
/**
     * Enum indicating the bluetooth event for user
     */
    enum class BluetoothEvent {
        ON_CONNECT,
        ON_DISCONNECT,
        ON_ENTER_DISCOVERABLE_MODE,
        ON_EXIT_DISCOVERABLE_MODE,
        PLAYING,
        PAUSED,
        STOPPED
    };

    /**
     * Enum indicating the bluetooth cmd from user
     */
    enum class BluetoothCmd {
        TURN_ON,
        TURN_OFF,
        PLAY,
        STOP,
        PAUSE,
        NEXT,
        PREVIOUS
    };

    virtual void onConnected(void) = 0;
    virtual void onDisconnected(void) = 0;
    virtual void onEnterDiscoverableMode(void) = 0;
    virtual void onExitDiscoverableMode(void) = 0;
    virtual void onPlaying(void) = 0;
    virtual void onPaused(void) = 0;
    virtual void onStopped(void) = 0;
};

/**
 *  AzeroFileUploaderEngineInterface
 */
class AzeroFileUploaderEngineInterface {
public:
    virtual bool sendFile(const std::string& file) = 0;
};

/**
 * Provides a string representation for an @c EqualizerControllerEngineInterface::EqualizerBand
 *
 * @param band The @c EqualizerBand
 * @return A string representation for the @c EqualizerBand
 */
inline std::string equalizerBandToString( const EqualizerControllerEngineInterface::EqualizerBand& band ) {
    switch (band) {
        case EqualizerControllerEngineInterface::EqualizerBand::BASS:
            return "BASS";
        case EqualizerControllerEngineInterface::EqualizerBand::MIDRANGE:
            return "MIDRANGE";
        case EqualizerControllerEngineInterface::EqualizerBand::TREBLE:
            return "TREBLE";
    }
    return "UNKNOWN";
}

/**
 * Write an @c EqualizerControllerEngineInterface::EqualizerBand value to an @c ostream as a string
 *
 * @param stream The stream to write to
 * @param band The @c EqualizerBand value to write to the @c ostream
 * @return The @c ostream argument that was written to
 */
inline std::ostream& operator<<( std::ostream& stream, const EqualizerControllerEngineInterface::EqualizerBand& band ) {
    stream << equalizerBandToString(band);
    return stream;
}

} // aace::alexa
} // aace

#pragma pop_macro("NO_ERROR")

#endif // AACE_ALEXA_ALEXA_ENGINE_INTERFACES_H
