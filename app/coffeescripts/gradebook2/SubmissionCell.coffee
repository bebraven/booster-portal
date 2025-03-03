define [
  'compiled/gradebook2/GRADEBOOK_TRANSLATIONS'
  'str/htmlEscape'
  'jquery'
  'underscore'
  'compiled/gradebook2/Turnitin'
  'compiled/util/round'
  'jquery.ajaxJSON'
  'jquery.instructure_misc_helpers' # raw
], (GRADEBOOK_TRANSLATIONS, htmlEscape,$, _, {extractData},round) ->

  class SubmissionCell

    constructor: (@opts) ->
      @init()

    init: () ->
      submission = @opts.item[@opts.column.field]
      @$wrapper = $(@cellWrapper("<input #{htmlEscape @ariaLabel(submission.submission_type)} class='grade'/>")).appendTo(@opts.container)
      @$input = @$wrapper.find('input').focus().select()

    destroy: () ->
      @$input.remove()

    focus: () ->
      @$input.focus()

    loadValue: () ->
      @val = if @opts.item[@opts.column.field].excused
        "EX"
      else
        @val = htmlEscape @opts.item[@opts.column.field].grade || ""
      @$input.val(@val)
      @$input[0].defaultValue = @val
      @$input.select()

    serializeValue: () ->
      @$input.val()

    applyValue: (item, state) ->
      submission = item[@opts.column.field]
      if state.toUpperCase() == "EX"
        submission.excused = true
      else
        submission.grade = htmlEscape state
      @wrapper?.remove()
      @postValue(item, state)
      # TODO: move selection down to the next row, same column

    postValue: (item, state) ->
      submission = item[@opts.column.field]
      url = @opts.grid.getOptions().change_grade_url
      url = url.replace(":assignment", submission.assignment_id).replace(":submission", submission.user_id)
      data = if state.toUpperCase() == "EX"
        {"submission[excuse]": true}
      else
        {"submission[posted_grade]": state}
      $.ajaxJSON url, "PUT", data, @onUpdateSuccess, @onUpdateError

    onUpdateSuccess: (submission) ->
      $.publish('submissions_updated', [submission.all_submissions])

    onUpdateError: ->
      $.flashError(GRADEBOOK_TRANSLATIONS.submission_update_error)

    isValueChanged: () ->
      @val != @$input.val()

    validate: () ->
      { valid: true, msg: null }

    @formatter: (row, col, submission, assignment, student) ->
      if submission.excused
        grade = "EX"
      else
        grade = parseFloat submission.grade
        grade = if isNaN(grade)
          submission.grade
        else
          round(grade, round.DEFAULT)

        if grade && assignment?.grading_type == "percent"
          grade = grade.toString() + "%"

      this.prototype.cellWrapper(grade, {submission: submission, assignment: assignment, editable: false, student: student})

    cellWrapper: (innerContents, options = {}) ->
      opts = $.extend({}, {
        classes: '',
        editable: true,
        student: {
          isInactive: false,
          isConcluded: false,
        }
      }, options)
      opts.submission ||= @opts.item[@opts.column.field]
      opts.assignment ||= @opts.column.object
      submission_type = opts.submission.submission_type if opts.submission?.submission_type || null
      specialClasses = SubmissionCell.classesBasedOnSubmission(opts.submission, opts.assignment)
      specialClasses.push("grayed-out") if opts.student.isInactive || opts.student.isConcluded
      specialClasses.push("cannot_edit") if opts.student.isConcluded
      opts.editable = false if opts.student.isConcluded

      opts.classes += ' no_grade_yet ' unless opts.submission.grade && opts.submission.workflow_state != 'pending_review'
      innerContents = null if opts.submission.workflow_state == 'pending_review' && !isNaN(innerContents)
      innerContents ?= if submission_type then SubmissionCell.submissionIcon(submission_type) else '-'

      if turnitin = extractData(opts.submission)
        specialClasses.push('turnitin')
        innerContents += "<span class='gradebook-cell-turnitin #{htmlEscape turnitin.state}-score' />"

      tooltipText = $.map(specialClasses, (c)-> GRADEBOOK_TRANSLATIONS["submission_tooltip_#{c}"]).join ', '

      cellCommentHTML = if !opts.student.isConcluded
        """
        <a href="#" data-user-id=#{opts.submission.user_id} data-assignment-id=#{opts.assignment.id} class="gradebook-cell-comment"><span class="gradebook-cell-comment-label">submission comments</span></a>
        """
      else
        ''

      """
      #{$.raw if tooltipText then '<div class="gradebook-tooltip">'+ htmlEscape(tooltipText) + '</div>' else ''}
      <div class="gradebook-cell #{htmlEscape if opts.editable then 'gradebook-cell-editable focus' else ''} #{htmlEscape opts.classes} #{htmlEscape specialClasses.join(' ')}">
        #{$.raw cellCommentHTML}
        #{$.raw innerContents}
      </div>
      """

    ariaLabel: (submission_type) ->
      label = GRADEBOOK_TRANSLATIONS["submission_tooltip_#{submission_type}"]
      if label?
        "aria-label='#{label}'"
      else
        ""

    @classesBasedOnSubmission: (submission={}, assignment={}) ->
      classes = []
      classes.push('resubmitted') if submission.grade_matches_current_submission == false
      classes.push('late') if submission.late
      classes.push('ungraded') if ''+assignment.submission_types is "not_graded"
      classes.push('muted') if assignment.muted
      classes.push(submission.submission_type) if submission.submission_type
      classes

    @submissionIcon: (submission_type) ->
      klass = SubmissionCell.iconFromSubmissionType(submission_type)
      "<i class='icon-#{htmlEscape klass}' ></i>"

    @iconFromSubmissionType: (submission_type) ->
      switch submission_type
        when "online_upload"
          "document"
        when "discussion_topic"
          "discussion"
        when "online_text_entry"
          "text"
        when "online_url"
          "link"
        when "media_recording"
          "filmstrip"
        when "online_quiz"
          "quiz"

  class SubmissionCell.out_of extends SubmissionCell
    init: () ->
      submission = @opts.item[@opts.column.field]
      
      @$wrapper = $(@cellWrapper("""
        <div class="overflow-wrapper">
          <div class="grade-and-outof-wrapper">
            <input aria-label="Grade" type="text" #{htmlEscape @ariaLabel(submission.submission_type)} class="grade"/><span class="outof"><span class="divider">/</span>#{htmlEscape @opts.column.object.points_possible}</span>
          </div>
        </div>
      """, { classes: 'gradebook-cell-out-of-formatter' })).appendTo(@opts.container)
      @$input = @$wrapper.find('input').focus().select()

  class SubmissionCell.letter_grade extends SubmissionCell
    @formatter: (row, col, submission, assignment, student) ->
      innerContents = if submission.excused
        "EX"
      else if submission.score?
        "#{htmlEscape submission.grade}<span class='letter-grade-points'>#{htmlEscape submission.score}</span>"
      else
        submission.grade

      SubmissionCell.prototype.cellWrapper(innerContents, {submission: submission, assignment: assignment, editable: false, student: student})

  class SubmissionCell.gpa_scale extends SubmissionCell
    @formatter: (row, col, submission, assignment, student) ->
      innerContents = if submission.excused
        "EX"
      else
        submission.grade

      SubmissionCell.prototype.cellWrapper(innerContents, {submission: submission, assignment: assignment, editable: false, student: student, classes: "gpa_scale_cell"})

  class SubmissionCell.pass_fail extends SubmissionCell

    states = ['pass', 'fail', '']
    classFromSubmission = (submission) ->
      if submission.excused
        "EX"
      else
        { pass: 'pass', complete: 'pass', fail: 'fail', incomplete: 'fail' }[submission.grade] || ''

    iconClassFromSubmission = (submission) ->
        { pass: 'icon-check', complete: 'icon-check', fail: 'icon-x', incomplete: 'icon-x' }[submission.grade] || ''

    htmlFromSubmission: (options={}) ->
      cssClass = classFromSubmission(options.submission)
      iconClass = iconClassFromSubmission(options.submission)
      SubmissionCell::cellWrapper("""
        <a data-value="#{htmlEscape cssClass}"
           class="gradebook-checkbox gradebook-checkbox-#{htmlEscape cssClass}
           #{htmlEscape('editable' if options.editable)}" href="#">
           #{htmlEscape cssClass}</a>
        <i class="#{htmlEscape iconClass}" role="presentation"></i> """, options)

    @formatter: (row, col, submission, assignment, student) ->
      return SubmissionCell.formatter.apply(this, arguments) unless submission.grade?
      pass_fail::htmlFromSubmission({ submission, assignment, editable: false})

    init: () ->
      @$wrapper = $(@cellWrapper())
      @$wrapper = $(@htmlFromSubmission({
        submission: @opts.item[@opts.column.field],
        assignment: @opts.column.object,
        editable: true})
      ).appendTo(@opts.container)
      @$input = @$wrapper.find('.gradebook-checkbox')
        .bind('click keypress', (event) =>
          event.preventDefault()
          currentValue = @$input.data('value')
          if currentValue is 'pass'
            newValue = 'fail'
          else if currentValue is 'fail'
            newValue = ''
          else
            newValue = 'pass'
          @transitionValue(newValue)
        ).focus()

    destroy: () ->
      @$wrapper.remove()

    transitionValue: (newValue) ->
      @$input
        .removeClass('gradebook-checkbox-pass gradebook-checkbox-fail')
        .addClass('gradebook-checkbox-' + classFromSubmission(grade: newValue))
        .data('value', newValue)

    loadValue: () ->
      @val = @opts.item[@opts.column.field].grade || ""

    serializeValue: () ->
      @$input.data('value')

    isValueChanged: () ->
      @val != @$input.data('value')

  class SubmissionCell.points extends SubmissionCell

  SubmissionCell
