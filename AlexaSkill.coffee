# Coffeescript port from Amazon Alexa examples
# Alexa SDK for JavaScript v1.0.00
# Copyright (c) 2014-2015 Amazon.com, Inc. or its affiliates. All Rights Reserved. Use is subject to license terms.


class AlexaSkill
  constructor: (appId) ->
    @_appId = appId

  requestHandlers:
    LaunchRequest: (event, context, response) ->
      @eventHandlers.onLaunch.call this, event.request, event.session, response
      return
    IntentRequest: (event, context, response) ->
      @eventHandlers.onIntent.call this, event.request, event.session, response
      return
    SessionEndedRequest: (event, context) ->
      @eventHandlers.onSessionEnded event.request, event.session
      context.succeed()
      return

  ###
  # Override any of the eventHandlers as needed
  ###
  eventHandlers:
    onSessionStarted: (sessionStartedRequest, session) ->
    onLaunch: (launchRequest, session, response) ->
      throw 'onLaunch should be overriden by subclass'
      return
    onIntent: (intentRequest, session, response) ->
      intent = intentRequest.intent
      intentName = intentRequest.intent.name
      intentHandler = @intentHandlers[intentName]
      if intentHandler
        console.log 'dispatch intent = ' + intentName
        intentHandler.call this, intent, session, response
      else
        throw 'Unsupported intent = ' + intentName
      return
    onSessionEnded: (sessionEndedRequest, session) ->

  ###*
  # Subclasses should override the intentHandlers with the functions to handle specific intents.
  ###
  intentHandlers: {}

  execute: (event, context) ->
    try
      console.log 'session applicationId: ' + event.session.application.applicationId
      # Validate that this request originated from authorized source.
      if @_appId and event.session.application.applicationId != @_appId
        console.log 'The applicationIds don\'t match : ' + event.session.application.applicationId + ' and ' + @_appId
        throw 'Invalid applicationId'
      if !event.session.attributes
        event.session.attributes = {}
      if event.session.new
        @eventHandlers.onSessionStarted event.request, event.session
      # Route the request to the proper handler which may have been overriden.
      requestHandler = @requestHandlers[event.request.type]
      requestHandler.call this, event, context, new Response(context, event.session)
    catch e
      console.log 'Unexpected exception ' + e
      context.fail e
    return


class Response
  constructor: (context, session) ->
    @_context = context
    @_session = session
    return

  # Private function
  buildSpeechletResponse = (options) ->
    alexaResponse =
      outputSpeech:
        type: 'PlainText'
        text: options.output
      shouldEndSession: options.shouldEndSession
    if options.reprompt
      alexaResponse.reprompt = outputSpeech:
        type: 'PlainText'
        text: options.reprompt
    if options.cardTitle and options.cardContent
      alexaResponse.card =
        type: 'Simple'
        title: options.cardTitle
        content: options.cardContent
    returnResult =
      version: '1.0'
      response: alexaResponse
    if options.session and options.session.attributes
      returnResult.sessionAttributes = options.session.attributes
    returnResult

  tell: (speechOutput) ->
    @_context.succeed buildSpeechletResponse(
      session: @_session
      output: speechOutput
      shouldEndSession: true
    )
  tellWithCard: (speechOutput, cardTitle, cardContent) ->
    @_context.succeed buildSpeechletResponse(
      session: @_session
      output: speechOutput
      cardTitle: cardTitle
      cardContent: cardContent
      shouldEndSession: true
    )
  ask: (speechOutput, repromptSpeech) ->
    @_context.succeed buildSpeechletResponse(
      session: @_session
      output: speechOutput
      reprompt: repromptSpeech
      shouldEndSession: false
    )
  askWithCard: (speechOutput, repromptSpeech, cardTitle, cardContent) ->
    @_context.succeed buildSpeechletResponse(
      session: @_session
      output: speechOutput
      reprompt: repromptSpeech
      cardTitle: cardTitle
      cardContent: cardContent
      shouldEndSession: false
    )

module.exports = AlexaSkill
