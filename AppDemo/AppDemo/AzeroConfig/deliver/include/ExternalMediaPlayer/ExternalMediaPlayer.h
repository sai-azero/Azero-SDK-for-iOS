/*
 * Copyright 2017-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

#ifndef ALEXA_CLIENT_SDK_CAPABILITYAGENTS_EXTERNALMEDIAPLAYER_INCLUDE_EXTERNALMEDIAPLAYER_EXTERNALMEDIAPLAYER_H_
#define ALEXA_CLIENT_SDK_CAPABILITYAGENTS_EXTERNALMEDIAPLAYER_INCLUDE_EXTERNALMEDIAPLAYER_EXTERNALMEDIAPLAYER_H_

#include <map>
#include <memory>
#include <string>

#ifdef EXTERNALMEDIAPLAYER_1_1
#include <AVSCommon/AVS/CapabilityConfiguration.h>
#include <AVSCommon/AVS/PlayerActivity.h>
#include <AVSCommon/SDKInterfaces/ExternalMediaAdapterHandlerInterface.h>
#endif
#include <AVSCommon/AVS/CapabilityAgent.h>
#include <AVSCommon/AVS/DirectiveHandlerConfiguration.h>
#include <AVSCommon/SDKInterfaces/CapabilityConfigurationInterface.h>
#include <AVSCommon/SDKInterfaces/ContextManagerInterface.h>
#include <AVSCommon/SDKInterfaces/ExternalMediaAdapterInterface.h>
#include <AVSCommon/SDKInterfaces/ExternalMediaPlayerInterface.h>
#include <AVSCommon/SDKInterfaces/ExternalMediaPlayerObserverInterface.h>
#include <AVSCommon/SDKInterfaces/FocusManagerInterface.h>
#include <AVSCommon/SDKInterfaces/MessageSenderInterface.h>
#include <AVSCommon/SDKInterfaces/PlaybackHandlerInterface.h>
#include <AVSCommon/SDKInterfaces/PlaybackRouterInterface.h>
#include <AVSCommon/SDKInterfaces/SpeakerManagerInterface.h>
#include <AVSCommon/AVS/NamespaceAndName.h>
#include <AVSCommon/Utils/MediaPlayer/MediaPlayerInterface.h>
#include <AVSCommon/Utils/RequiresShutdown.h>
#include <AVSCommon/Utils/Threading/Executor.h>

namespace alexaClientSDK {
namespace capabilityAgents {
namespace externalMediaPlayer {

#ifdef EXTERNALMEDIAPLAYER_1_1
/// Enum to identify the initiator type of a stop.
enum class HaltInitiator {
    /// The system is not halted.
    NONE,

    /// Voice initiated Pause request from AVS/Pause from Spotify Connect.
    EXTERNAL_PAUSE,

    /// Pause was initiated when focus changed from FOREGROUND to BACKGROUND.
    FOCUS_CHANGE_PAUSE,

    /// Stop initiated when focus changed from FOREGROUND/BACKGROUND to NONE.
    FOCUS_CHANGE_STOP
};
#endif

/**
 * This class implements the @c ExternalMediaPlayer capability agent. This agent is responsible for handling
 * music service providers which manage their PLAY queue.
 *
 * @note For instances of this class to be cleaned up correctly, @c shutdown() must be called.
 */
class ExternalMediaPlayer
        : public avsCommon::avs::CapabilityAgent
        , public avsCommon::utils::RequiresShutdown
        , public avsCommon::sdkInterfaces::CapabilityConfigurationInterface
        , public avsCommon::sdkInterfaces::ExternalMediaPlayerInterface
        , public avsCommon::sdkInterfaces::PlaybackHandlerInterface
        , public std::enable_shared_from_this<ExternalMediaPlayer> {
public:
    // Map of adapter business names to their mediaPlayers.
    using AdapterMediaPlayerMap =
        std::unordered_map<std::string, std::shared_ptr<avsCommon::utils::mediaPlayer::MediaPlayerInterface>>;

    // Map of adapter business names to their speakers.
    using AdapterSpeakerMap =
        std::unordered_map<std::string, std::shared_ptr<avsCommon::sdkInterfaces::SpeakerInterface>>;

    // Signature of functions to create an ExternalMediaAdapter.
    using AdapterCreateFunction =
        std::shared_ptr<avsCommon::sdkInterfaces::externalMediaPlayer::ExternalMediaAdapterInterface> (*)(
            std::shared_ptr<avsCommon::utils::mediaPlayer::MediaPlayerInterface> mediaPlayer,
            std::shared_ptr<avsCommon::sdkInterfaces::SpeakerInterface> speaker,
            std::shared_ptr<avsCommon::sdkInterfaces::SpeakerManagerInterface> speakerManager,
            std::shared_ptr<avsCommon::sdkInterfaces::MessageSenderInterface> messageSender,
            std::shared_ptr<avsCommon::sdkInterfaces::FocusManagerInterface> focusManager,
            std::shared_ptr<avsCommon::sdkInterfaces::ContextManagerInterface> contextManager,
            std::shared_ptr<avsCommon::sdkInterfaces::ExternalMediaPlayerInterface> externalMediaPlayer);

    // Map of adapter business names to their creation method.
    using AdapterCreationMap = std::unordered_map<std::string, AdapterCreateFunction>;

    /**
     * Creates a new @c ExternalMediaPlayer instance.
     *
     * @param mediaPlayers The map of <PlayerId, MediaPlayer> to be used to find the mediaPlayer to use for this
     * adapter.
     * @param speakers The map of <PlayerId, SpeakerInterface> to be used to find the speaker to use for this
     * adapter.
     * @param adapterCreationMap The map of <PlayerId, AdapterCreateFunction> to be used to create the adapters.
     * @param speakerManager A @c SpeakerManagerInterface to perform volume changes requested by adapters.
     * @param messageSender The object to use for sending events.
     * @param focusManager The object used to manage focus for the adapter managed by the EMP.
     * @param contextManager The AVS Context manager used to generate system context for events.
     * @param exceptionSender The object to use for sending AVS Exception messages.
     * @param playbackRouter The @c PlaybackRouterInterface instance to use when @c ExternalMediaPlayer becomes active.
     * @return A @c std::shared_ptr to the new @c ExternalMediaPlayer instance.
     */
    static std::shared_ptr<ExternalMediaPlayer> create(
        const AdapterMediaPlayerMap& mediaPlayers,
        const AdapterSpeakerMap& speakers,
        const AdapterCreationMap& adapterCreationMap,
        std::shared_ptr<avsCommon::sdkInterfaces::SpeakerManagerInterface> speakerManager,
        std::shared_ptr<avsCommon::sdkInterfaces::MessageSenderInterface> messageSender,
        std::shared_ptr<avsCommon::sdkInterfaces::FocusManagerInterface> focusManager,
        std::shared_ptr<avsCommon::sdkInterfaces::ContextManagerInterface> contextManager,
        std::shared_ptr<avsCommon::sdkInterfaces::ExceptionEncounteredSenderInterface> exceptionSender,
        std::shared_ptr<avsCommon::sdkInterfaces::PlaybackRouterInterface> playbackRouter);

#ifdef EXTERNALMEDIAPLAYER_1_1
    void addAdapterHandler(std::shared_ptr<avsCommon::sdkInterfaces::ExternalMediaAdapterHandlerInterface> adapterHandler);
    void removeAdapterHandler(std::shared_ptr<avsCommon::sdkInterfaces::ExternalMediaAdapterHandlerInterface> adapterHandler);
#endif

#ifdef EXTERNALMEDIAPLAYER_1_1
    void executeOnFocusChanged(avsCommon::avs::FocusState newFocus);

    void onFocusChanged(avsCommon::avs::FocusState newFocus) override;

    void onContextAvailable(const std::string& jsonContext) override;

    void onContextFailure(const avsCommon::sdkInterfaces::ContextRequestError error) override;
#endif

    /// @name StateProviderInterface Functions
    /// @{
    void provideState(const avsCommon::avs::NamespaceAndName& stateProviderName, unsigned int stateRequestToken)
        override;
    /// @}

    /// @name CapabilityAgent/DirectiveHandlerInterface Functions
    /// @{
    void handleDirectiveImmediately(std::shared_ptr<avsCommon::avs::AVSDirective> directive) override;
    void preHandleDirective(std::shared_ptr<DirectiveInfo> info) override;
    void handleDirective(std::shared_ptr<DirectiveInfo> info) override;
    void cancelDirective(std::shared_ptr<DirectiveInfo> info) override;
    void onDeregistered() override;
    avsCommon::avs::DirectiveHandlerConfiguration getConfiguration() const override;
    /// @}

    /// @name Overridden PlaybackHandlerInterface methods.
    /// @{
    virtual void onButtonPressed(avsCommon::avs::PlaybackButton button) override;

    virtual void onTogglePressed(avsCommon::avs::PlaybackToggle toggle, bool action) override;
    /// @}

    /// @name Overridden ExternalMediaPlayerInterface methods.
    /// @{
#ifdef EXTERNALMEDIAPLAYER_1_1
    virtual void setCurrentActivity(const avsCommon::avs::PlayerActivity currentActivity) override;

    virtual void setPlayerInFocus(const std::string& playerInFocus, bool focusAcquire) override;
#endif

    virtual void setPlayerInFocus(const std::string& playerInFocus) override;
    /// @}

    /// @name CapabilityConfigurationInterface Functions
    /// @{
    std::unordered_set<std::shared_ptr<avsCommon::avs::CapabilityConfiguration>> getCapabilityConfigurations() override;
    /// @}

    /**
     * Adds an observer which will be notified on any observable state changes
     *
     * @param observer The observer to add
     */
    void addObserver(
        const std::shared_ptr<avsCommon::sdkInterfaces::externalMediaPlayer::ExternalMediaPlayerObserverInterface>
            observer);

    /**
     * Removes an observer from the list of active watchers
     *
     *@param observer The observer to remove
     */
    void removeObserver(
        const std::shared_ptr<avsCommon::sdkInterfaces::externalMediaPlayer::ExternalMediaPlayerObserverInterface>
            observer);

private:
    /**
     * Constructor.
     *
     * @param speakerManager A @c SpeakerManagerInterface to perform volume changes requested by adapters.
     * @param contextManager The AVS Context manager used to generate system context for events.
     * @param exceptionSender The object to use for sending AVS Exception messages.
     * @param playbackRouter The @c PlaybackRouterInterface instance to use when @c ExternalMediaPlayer becomes active.
     * @return A @c std::shared_ptr to the new @c ExternalMediaPlayer instance.
     */
    ExternalMediaPlayer(
        std::shared_ptr<avsCommon::sdkInterfaces::SpeakerManagerInterface> speakerManager,
        std::shared_ptr<avsCommon::sdkInterfaces::ContextManagerInterface> contextManager,
        std::shared_ptr<avsCommon::sdkInterfaces::ExceptionEncounteredSenderInterface> exceptionSender,
        std::shared_ptr<avsCommon::sdkInterfaces::PlaybackRouterInterface> playbackRouter);

    /**
     * This method returns the ExternalMediaPlayer session state registered in the ExternalMediaPlayer namespace.
     */
#ifdef EXTERNALMEDIAPLAYER_1_1
    std::string provideSessionState(std::vector<avsCommon::sdkInterfaces::externalMediaPlayer::AdapterState> adapterStates);
#else
    std::string provideSessionState();
#endif

    /**
     * This method returns the Playback state registered in the Alexa.PlaybackStateReporter state.
     */
#ifdef EXTERNALMEDIAPLAYER_1_1
    std::string providePlaybackState(std::vector<avsCommon::sdkInterfaces::externalMediaPlayer::AdapterState> adapterStates);
#else
    std::string providePlaybackState();
#endif

    /**
     * This function deserializes a @c Directive's payload into a @c rapidjson::Document.
     *
     * @param info The @c DirectiveInfo to read the payload string from.
     * @param[out] document The @c rapidjson::Document to parse the payload into.
     * @return @c true if parsing was successful, else @c false.
     */
    bool parseDirectivePayload(std::shared_ptr<DirectiveInfo> info, rapidjson::Document* document);

    /**
     * Remove a directive from the map of message IDs to DirectiveInfo instances.
     *
     * @param info The @c DirectiveInfo containing the @c AVSDirective whose message ID is to be removed.
     */
    void removeDirective(std::shared_ptr<DirectiveInfo> info);

    /// @name RequiresShutdown Functions
    /// @{
    void doShutdown() override;
    /// @}

    /**
     * Method to create all the adapters registered.
     *
     * @param mediaPlayers The map of <PlayerId, MediaPlayer> to be used to find the mediaPlayer to use for this
     * adapter.
     * @param speakers The map of <PlayerId, SpeakerInterface> to be used to find the speaker to use for this
     * adapter.
     * @param adapterCreationMap The map of <PlayerId, AdapterCreateFunction> to be used to create the adapters.
     * @param messageSender The messager sender of the adapter.
     * @param focusManager The focus manager to be used by the adapter to acquire/release channel.
     * @param contextManager The context manager of the ExternalMediaPlayer and adapters.
     */
    void createAdapters(
        const AdapterMediaPlayerMap& mediaPlayers,
        const AdapterSpeakerMap& speakers,
        const AdapterCreationMap& adapterCreationMap,
        std::shared_ptr<avsCommon::sdkInterfaces::MessageSenderInterface> messageSender,
        std::shared_ptr<avsCommon::sdkInterfaces::FocusManagerInterface> focusManager,
        std::shared_ptr<avsCommon::sdkInterfaces::ContextManagerInterface> contextManager);

#ifdef EXTERNALMEDIAPLAYER_1_1
    /**
     * Set the appropriate halt initiator for the request.
     *
     * @param The type of the request.
     */
    void setHaltInitiatorRequestHelper(avsCommon::sdkInterfaces::externalMediaPlayer::RequestType request);
#endif

    /**
     * Send the handling completed notification and clean up the resources the specified @c DirectiveInfo.
     *
     * @param info The @c DirectiveInfo to complete and clean up.
     */
    void setHandlingCompleted(std::shared_ptr<DirectiveInfo> info);

    /**
     * Send ExceptionEncountered and report a failure to handle the @c AVSDirective.
     *
     * @param info The @c AVSDirective that encountered the error and ancillary information.
     * @param type The type of Exception that was encountered.
     * @param message The error message to include in the ExceptionEncountered message.
     */
    void sendExceptionEncounteredAndReportFailed(
        std::shared_ptr<DirectiveInfo> info,
        const std::string& message,
        avsCommon::avs::ExceptionErrorType type = avsCommon::avs::ExceptionErrorType::INTERNAL_ERROR);

    /**
     * @name Executor Thread Functions
     *
     * These functions (and only these functions) are called by @c m_executor on a single worker thread.  All other
     * functions in this class can be called asynchronously, and pass data to the @c Executor thread through parameters
     * to lambda functions.  No additional synchronization is needed.
     */
    /// @{
    /**
     * This function provides updated context information for @c ExternalMediaPlayer to @c ContextManager.  This
     * function is called when @c ContextManager calls @c provideState(), and is also called internally by @c
     * changeActivity().
     *
     * @param stateProviderName The name of the stateProvider.
     * @param sendToken flag indicating whether @c stateRequestToken contains a valid token which should be passed
     *     along to @c ContextManager.  This flag defaults to @c false.
     * @param stateRequestToken The token @c ContextManager passed to the @c provideState() call, which will be passed
     *     along to the ContextManager::setState() call.  This parameter is not used if @c sendToken is @c false.
     */
    void executeProvideState(
        const avsCommon::avs::NamespaceAndName& stateProviderName,
        bool sendToken = false,
        unsigned int stateRequestToken = 0);
    /// @}

    /**
     * Method that checks the preconditions for all directives.
     *
     * @param info The DirectiveInfo to be preprocessed
     * @param document The rapidjson document resulting from parsing the directive in directiveInfo.
     * @return A shared-ptr to the ExternalMediaAdapterInterface on which the actual
     *        adapter method has to be invoked.
     */
    std::shared_ptr<avsCommon::sdkInterfaces::externalMediaPlayer::ExternalMediaAdapterInterface> preprocessDirective(
        std::shared_ptr<DirectiveInfo> info,
        rapidjson::Document* document);

#ifdef EXTERNALMEDIAPLAYER_1_1
    /**
     * Handler for AuthorizeDiscoveredPlayers directive.
     *
     * @param info The DirectiveInfo to be processed.
     * @param The type of the request. Will be NONE for the
     *        handleAuthorizeDiscoveredPlayers case.
     */
    void handleAuthorizeDiscoveredPlayers(
        std::shared_ptr<DirectiveInfo> info,
        avsCommon::sdkInterfaces::externalMediaPlayer::RequestType request);
#endif

    /**
     * Handler for login directive.
     *
     * @param info The DirectiveInfo to be processed.
     * @param The type of the request. Will be LOGIN for the handleLogin case.
     */
    void handleLogin(
        std::shared_ptr<DirectiveInfo> info,
        avsCommon::sdkInterfaces::externalMediaPlayer::RequestType request);

    /**
     * Handler for logout directive.
     *
     * @param info The DirectiveInfo to be processed.
     * @param The type of the request. Will be LOGOUT for the handleLogout case.
     */
    void handleLogout(
        std::shared_ptr<DirectiveInfo> info,
        avsCommon::sdkInterfaces::externalMediaPlayer::RequestType request);

    /**
     * Handler for play directive.
     *
     * @param info The DirectiveInfo to be processed.
     * @param The type of the request. Will be PLAY for the handlePlay case.
     */
    void handlePlay(
        std::shared_ptr<DirectiveInfo> info,
        avsCommon::sdkInterfaces::externalMediaPlayer::RequestType request);

    /**
     * Handler for play control directive.
     *
     * @param info The DirectiveInfo to be processed.
     * @param The type of the request. Can be NEXT/PREVIOUS/PAUSE/RESUME... for the handlePlayControl case.
     */
    void handlePlayControl(
        std::shared_ptr<DirectiveInfo> info,
        avsCommon::sdkInterfaces::externalMediaPlayer::RequestType request);

    /**
     * Handler for SetSeekControl  directive.
     *
     * @param info The DirectiveInfo to be processed.
     * @param The type of the request. RequestType will be SEEK.
     */
    void handleSeek(
        std::shared_ptr<DirectiveInfo> info,
        avsCommon::sdkInterfaces::externalMediaPlayer::RequestType request);

    /**
     * Handler for AdjustSeekControl  directive.
     *
     * @param info The DirectiveInfo to be processed.
     * @param The type of the request. RequestType will be ADJUST_SEEK.
     */
    void handleAdjustSeek(
        std::shared_ptr<DirectiveInfo> info,
        avsCommon::sdkInterfaces::externalMediaPlayer::RequestType request);

    /**
     * Calls each observer and provides the ObservableSessionProperties for this adapter
     *
     * @param playerId the ExternalMediaAdapter being reported on
     * @param sessionProperties  the observable session properties being reported
     */
    void notifyObservers(
        const std::string& playerId,
        const avsCommon::sdkInterfaces::externalMediaPlayer::ObservableSessionProperties* sessionProperties);

    /**
     * Calls each observer and provides the ObservablePlaybackStateProperties for this adapter
     *
     * @param playerId the ExternalMediaAdapter being reported on
     * @param playbackProperties  the observable playback state properties being reported
     */
    void notifyObservers(
        const std::string& playerId,
        const avsCommon::sdkInterfaces::externalMediaPlayer::ObservablePlaybackStateProperties* playbackProperties);

    /**
     * Calls each observer and provides the supplied ObservableProperties for this adapter
     *
     * @param adapter the ExternalMediaAdapter being reported on
     * @param sessionProperties  the observable session properties being reported
     * @param playbackProperties  the observable playback state properties being reported
     */
    void notifyObservers(
        const std::string& playerId,
        const avsCommon::sdkInterfaces::externalMediaPlayer::ObservableSessionProperties* sessionProperties,
        const avsCommon::sdkInterfaces::externalMediaPlayer::ObservablePlaybackStateProperties* playbackProperties);

    /// The @c SpeakerManagerInterface used to change the volume when requested by @c ExternalMediaAdapterInterface.
    std::shared_ptr<avsCommon::sdkInterfaces::SpeakerManagerInterface> m_speakerManager;

    /// The @c ContextManager that needs to be updated of the state.
    std::shared_ptr<avsCommon::sdkInterfaces::ContextManagerInterface> m_contextManager;

    /// The @c PlaybackRouterInterface instance to use when @c ExternalMediaPlayer becomes active.
    std::shared_ptr<avsCommon::sdkInterfaces::PlaybackRouterInterface> m_playbackRouter;

    /// The @ m_adapters Map of business names to the adapters.
    std::map<std::string, std::shared_ptr<avsCommon::sdkInterfaces::externalMediaPlayer::ExternalMediaAdapterInterface>>
        m_adapters;

    /// The id of the player which currently has focus.
    std::string m_playerInFocus;

    /// Mutex to serialize access to the observers.
    std::mutex m_observersMutex;

    /// The set of observers watching session and playback state
    std::unordered_set<
        std::shared_ptr<avsCommon::sdkInterfaces::externalMediaPlayer::ExternalMediaPlayerObserverInterface>>
        m_observers;

#ifdef EXTERNALMEDIAPLAYER_1_1
    std::unordered_set<std::shared_ptr<avsCommon::sdkInterfaces::ExternalMediaAdapterHandlerInterface>> m_adapterHandlers;
#endif

#ifdef EXTERNALMEDIAPLAYER_1_1
    /// The @c FocusManager used to manage usage of the channel.
    std::shared_ptr<avsCommon::sdkInterfaces::FocusManagerInterface> m_focusManager;

    /// The current focus state of the @c AudioPlayer on the content channel.
    avsCommon::avs::FocusState m_focus;

    /// bool to identify if acquire of focus is currently in progress.
    bool m_focusAcquireInProgress;

    /// Enum to identify the type and source of the halt request.
    HaltInitiator m_haltInitiator;

    /// The current state of the @c ExternalMediaPlayer.
    avsCommon::avs::PlayerActivity m_currentActivity;

    /// Protects writes to @c m_currentActivity and waiting on @c m_currentActivityConditionVariable.
    std::mutex m_currentActivityMutex;

    /// Provides notifications of changes to @c m_currentActivity.
    std::condition_variable m_currentActivityConditionVariable;
#endif

    /**
     * @c Executor which queues up operations from asynchronous API calls.
     *
     * @note This declaration needs to come *after* the Executor Thread Variables above so that the thread shuts down
     *     before the Executor Thread Variables are destroyed.
     */
    avsCommon::utils::threading::Executor m_executor;

    /// typedef of the function pointer to handle AVS directives.
    typedef void (ExternalMediaPlayer::*DirectiveHandler)(
        std::shared_ptr<DirectiveInfo> info,
        avsCommon::sdkInterfaces::externalMediaPlayer::RequestType request);

    /// The singleton map from a directive to its handler.
    static std::unordered_map<
        avsCommon::avs::NamespaceAndName,
        std::pair<avsCommon::sdkInterfaces::externalMediaPlayer::RequestType, ExternalMediaPlayer::DirectiveHandler>>
        m_directiveToHandlerMap;

    /// Set of capability configurations that will get published using the Capabilities API
    std::unordered_set<std::shared_ptr<avsCommon::avs::CapabilityConfiguration>> m_capabilityConfigurations;
};

}  // namespace externalMediaPlayer
}  // namespace capabilityAgents
}  // namespace alexaClientSDK

#endif  // ALEXA_CLIENT_SDK_CAPABILITYAGENTS_EXTERNALMEDIAPLAYER_INCLUDE_EXTERNALMEDIAPLAYER_EXTERNALMEDIAPLAYER_H_
