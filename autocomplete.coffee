class Autocomplete
  constructor: (el) ->
    @$el = $(el)

    @$input    = @$el.find('input[type="text"]')
    @$fieldset = @$el.find('fieldset')
    @$radios   = @$fieldset.find('input[type="radio"]')
    @$alerts   = @$el.find('#alerts')

    @applyCheckedOptionToInput()
    @announceOptionsCount('')

    @attachEvents()

  attachEvents: ->
    @attachClickEventToInput()
    @attachChangeEventToInput()

    @attachEscapeKeyToInput()
    @attachEnterKeyToInput()
    @attachTabKeyToInput()
    @attachUpDownKeysToInput()

    @attachChangeEventToOptions()
    @attachClickEventToOptions()

  attachClickEventToInput: ->
    @$input.click =>
      if !@$fieldset.attr('hidden')
        @hideOptions()
      else
        @showOptions()

  attachEscapeKeyToInput: ->
    @$input.keydown (e) =>
      if e.which == 27
        if !@$fieldset.attr('hidden')
          @applyCheckedOptionToInputAndResetOptions()
          e.preventDefault()
        else if @$radios.is(':checked')
          @$radios.prop('checked', false)
          @applyCheckedOptionToInputAndResetOptions()
          e.preventDefault()
        else # Needed for automatic testing only
          $('body').append('<p>Esc passed on.</p>')

  attachEnterKeyToInput: ->
    @$input.keydown (e) =>
      if e.which == 13
        if !@$fieldset.attr('hidden')
          @applyCheckedOptionToInputAndResetOptions()
          e.preventDefault()
        else # Needed for automatic testing only
          $('body').append('<p>Enter passed on.</p>')

  attachTabKeyToInput: ->
    @$input.keydown (e) =>
      if e.which == 9
        if !@$fieldset.attr('hidden')
          @applyCheckedOptionToInputAndResetOptions()

  attachUpDownKeysToInput: ->
    @$input.keydown (e) =>
      if e.which == 38 || e.which == 40
        if !@$fieldset.attr('hidden')
          if e.which == 38
            @moveSelection('up')
          else
            @moveSelection('down')
        else
          @showOptions()

        e.preventDefault()

  showOptions: ->
    @$fieldset.removeAttr('hidden')
    @$input.attr('aria-expanded', 'true')

  hideOptions: ->
    @$fieldset.attr('hidden', '')
    @$input.attr('aria-expanded', 'false')

  moveSelection: (direction) ->
    $visibleOptions = @$radios.filter(':visible')

    maxIndex = $visibleOptions.length - 1
    currentIndex = $visibleOptions.index($visibleOptions.parent().find(':checked'))

    upcomingIndex = if direction == 'up'
                      if currentIndex <= 0
                        maxIndex
                      else
                        currentIndex - 1
                    else
                      if currentIndex == maxIndex
                        0
                      else
                        currentIndex + 1

    $upcomingOption = $($visibleOptions[upcomingIndex])
    $upcomingOption.prop('checked', true).trigger('change')

  attachChangeEventToOptions: ->
    @$radios.change (e) =>
      @applyCheckedOptionToInput()
      @$input.focus().select()

  applyCheckedOptionToInputAndResetOptions: ->
    @applyCheckedOptionToInput()
    @hideOptions()
    @applyFilterToOptions()

  applyCheckedOptionToInput: ->
    $previouslyCheckedOptionLabel = $(@$el.find('.selected'))
    if $previouslyCheckedOptionLabel.length == 1
      $previouslyCheckedOptionLabel.removeClass('selected')

    $checkedOption = @$radios.filter(':checked')
    if $checkedOption.length == 1
      $checkedOptionLabel = $(@$el.find("label[for='#{$checkedOption.attr('id')}']")[0])
      @$input.val($.trim($checkedOptionLabel.text()))
      $checkedOptionLabel.addClass('selected')
    else
      @$input.val('')

  attachClickEventToOptions: ->
    @$radios.click (e) =>
      @hideOptions()

  attachChangeEventToInput: ->
    @$input.on 'input propertychange paste', (e) =>
      @applyFilterToOptions(e.target.value)
      @showOptions()

  applyFilterToOptions: (filter = '') ->
    fuzzyFilter = @fuzzifyFilter(filter)
    visibleCount = 0

    @$radios.each (i, el) =>
      $option = $(el)
      $optionContainer = $option.parent()

      regex = new RegExp(fuzzyFilter, 'i')
      if regex.test($optionContainer.text())
        visibleCount++
        $optionContainer.removeAttr('hidden')
      else
        $optionContainer.attr('hidden', '')

    @announceOptionsCount(filter, visibleCount)

  announceOptionsCount: (filter = @$input.val(), count = @$radios.length) ->
    @$alerts.find('p').remove() # Remove previous alerts

    message = if filter == ''
                "#{count} options in total"
              else
                "#{count} of #{@$radios.length} options for <kbd>#{filter}</kbd>"

    @$alerts.append("<p role='alert'>#{message}</p>")

  fuzzifyFilter: (filter) ->
    i = 0
    fuzzifiedFilter = ''
    while i < filter.length
      escapedCharacter = filter.charAt(i).replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&") # See https://stackoverflow.com/questions/3446170/escape-string-for-use-in-javascript-regex
      fuzzifiedFilter += "#{escapedCharacter}.*?"
      i++

    fuzzifiedFilter

$(document).ready ->
  $('[data-autocomplete]').each ->
    new Autocomplete @
