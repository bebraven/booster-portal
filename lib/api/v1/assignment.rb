#
# Copyright (C) 2011 - 2014 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

module Api::V1::Assignment
  include Api::V1::Json
  include ApplicationHelper
  include Api::V1::ExternalTools::UrlHelpers
  include Api::V1::Locked
  include Api::V1::AssignmentOverride

  API_ALLOWED_ASSIGNMENT_OUTPUT_FIELDS = {
    :only => %w(
      id
      clone_of_id
      position
      description
      points_possible
      grading_type
      created_at
      updated_at
      due_at
      lock_at
      unlock_at
      assignment_group_id
      peer_reviews
      anonymous_peer_reviews
      automatic_peer_reviews
      post_to_sis
      grade_group_students_individually
      group_category_id
      grading_standard_id
      moderated_grading
    )
  }.freeze

  API_ASSIGNMENT_NEW_RECORD_FIELDS = {
    :only => %w(
      points_possible
      clone_of_id
      due_at
      assignment_group_id
      post_to_sis
    )
  }.freeze

  def assignments_json(assignments, user, session, opts = {})
    assignments.map{ |assignment| assignment_json(assignment, user, session, opts) }
  end

  def assignment_json(assignment, user, session, opts = {})
    opts.reverse_merge!(
      include_discussion_topic: true,
      include_all_dates: false,
      override_dates: true,
      needs_grading_count_by_section: false,
      exclude_response_fields: []
    )

    if opts[:override_dates] && !assignment.new_record?
      assignment = assignment.overridden_for(user)
    end

    fields = assignment.new_record? ? API_ASSIGNMENT_NEW_RECORD_FIELDS : API_ALLOWED_ASSIGNMENT_OUTPUT_FIELDS
    if opts[:exclude_response_fields].include?('description')
      fields_copy = fields[:only].dup
      fields_copy.delete("description")
      fields = {only: fields_copy}
    end

    hash = api_json(assignment, user, session, fields)
    hash['course_id'] = assignment.context_id
    hash['name'] = assignment.title
    hash['clone_of_id'] = assignment.clone_of_id
    hash['submission_types'] = assignment.submission_types_array
    hash['has_submitted_submissions'] = assignment.has_submitted_submissions?

    if !opts[:overrides].blank?
      hash['overrides'] = assignment_overrides_json(opts[:overrides], user)
    end

    if !assignment.user_submitted.nil?
      hash['user_submitted'] = assignment.user_submitted
    end

    if assignment.context && assignment.context.turnitin_enabled?
      hash['turnitin_enabled'] = assignment.turnitin_enabled
      hash['turnitin_settings'] = turnitin_settings_json(assignment)
    end

    if PluginSetting.settings_for_plugin(:assignment_freezer)
      hash['freeze_on_copy'] = assignment.freeze_on_copy?
      hash['frozen'] = assignment.frozen_for_user?(user)
      hash['frozen_attributes'] = assignment.frozen_attributes_for_user(user)
    end

    return hash if assignment.new_record?

    # use already generated hash['description'] because it is filtered by
    # Assignment#filter_attributes_for_user when the assignment is locked
    unless opts[:exclude_response_fields].include?('description')
      hash['description'] = api_user_content(hash['description'],
                                             @context || assignment.context,
                                             user,
                                             opts[:preloaded_user_content_attachments] || {})
    end

    can_manage = assignment.context.grants_any_right?(user, :manage, :manage_grades, :manage_assignments)
    hash['muted'] = assignment.muted?
    hash['html_url'] = course_assignment_url(assignment.context_id, assignment)
    if can_manage
      hash['has_overrides'] = assignment.has_overrides?
    end

    if assignment.external_tool? && assignment.external_tool_tag.present?
      external_tool_tag = assignment.external_tool_tag
      hash['external_tool_tag_attributes'] = {
        'url' => external_tool_tag.url,
        'new_tab' => external_tool_tag.new_tab,
        'resource_link_id' => ContextExternalTool.opaque_identifier_for(external_tool_tag, assignment.shard)
      }
      hash['url'] = sessionless_launch_url(@context,
                                           :launch_type => 'assessment',
                                           :assignment_id => assignment.id)
    end

    if assignment.automatic_peer_reviews? && assignment.peer_reviews?
      hash['peer_review_count'] = assignment.peer_review_count
      hash['peer_reviews_assign_at'] = assignment.peer_reviews_assign_at
    end

    include_needs_grading_count = opts[:exclude_response_fields].exclude?('needs_grading_count')
    if include_needs_grading_count && assignment.context.grants_right?(user, :manage_grades)
      query = Assignments::NeedsGradingCountQuery.new(assignment, user, opts[:needs_grading_course_proxy])
      if opts[:needs_grading_count_by_section]
        hash['needs_grading_count_by_section'] = query.count_by_section
      end
      hash['needs_grading_count'] = query.count
    end

    if assignment.context.grants_any_right?(user, :read_sis, :manage_sis)
      hash['integration_id'] = assignment.integration_id
      hash['integration_data'] = assignment.integration_data
    end

    if assignment.quiz
      hash['quiz_id'] = assignment.quiz.id
      hash['anonymous_submissions'] = !!(assignment.quiz.anonymous_submissions)
    end

    if assignment.allowed_extensions.present?
      hash['allowed_extensions'] = assignment.allowed_extensions
    end

    unless opts[:exclude_response_fields].include?('rubric')
      if assignment.rubric_association
        hash['use_rubric_for_grading'] = !!assignment.rubric_association.use_for_grading
        if assignment.rubric_association.rubric
          hash['free_form_criterion_comments'] = !!assignment.rubric_association.rubric.free_form_criterion_comments
        end
      end

      if assignment.rubric
        rubric = assignment.rubric
        hash['rubric'] = rubric.data.map do |row|
          row_hash = row.slice(:id, :points, :description, :long_description)
          row_hash["ratings"] = row[:ratings].map do |c|
            c.slice(:id, :points, :description)
          end
          if row[:learning_outcome_id] && outcome = LearningOutcome.where(id: row[:learning_outcome_id]).first
            row_hash["outcome_id"] = outcome.id
            row_hash["vendor_guid"] = outcome.vendor_guid
          end
          row_hash
        end
        hash['rubric_settings'] = {
          'id' => rubric.id,
          'title' => rubric.title,
          'points_possible' => rubric.points_possible,
          'free_form_criterion_comments' => !!rubric.free_form_criterion_comments
        }
      end
    end

    if opts[:include_discussion_topic] && assignment.discussion_topic
      extend Api::V1::DiscussionTopics
      hash['discussion_topic'] = discussion_topic_api_json(
        assignment.discussion_topic,
        assignment.discussion_topic.context,
        user,
        session,
        include_assignment: false, exclude_messages: opts[:exclude_response_fields].include?('description'))
    end

    if opts[:include_all_dates] && assignment.assignment_overrides
      hash['all_dates'] = assignment.dates_hash_visible_to(user)
    end

    if opts[:include_module_ids]
      thing_in_module = case assignment.submission_types
                        when "online_quiz" then assignment.quiz
                        when "discussion_topic" then assignment.discussion_topic
                        else assignment
                        end
      hash['module_ids'] = thing_in_module.context_module_tags.map(&:context_module_id) if thing_in_module
    end

    hash['published'] = ! assignment.unpublished?
    if can_manage
      hash['unpublishable'] = assignment.can_unpublish?
    end

    hash['only_visible_to_overrides'] = value_to_boolean(assignment.only_visible_to_overrides)

    if opts[:include_visibility]
      hash['assignment_visibility'] = (opts[:assignment_visibilities] || assignment.students_with_visibility.pluck(:id).uniq).map(&:to_s)
    end

    if submission = opts[:submission]
      if submission.is_a?(Array)
        hash['submission'] = submission.map { |s| submission_json(s, assignment, user, session) }
      else
        hash['submission'] = submission_json(submission, assignment, user, session)
      end
    end

    if opts[:bucket]
      hash['bucket'] = opts[:bucket]
    end

    locked_json(hash, assignment, user, 'assignment')

    if assignment.context.present?
      hash['submissions_download_url'] = submissions_download_url(assignment.context, assignment)
    end

    hash
  end

  def turnitin_settings_json(assignment)
    settings = assignment.turnitin_settings.with_indifferent_access
    [:s_paper_check, :internet_check, :journal_check, :exclude_biblio, :exclude_quoted, :submit_papers_to].each do |key|
      settings[key] = value_to_boolean(settings[key])
    end

    ex_type = settings.delete(:exclude_type)
    settings[:exclude_small_matches_type] = case ex_type
      when '0'; nil
      when '1'; 'words'
      when '2'; 'percent'
    end

    ex_value = settings.delete(:exclude_value)
    settings[:exclude_small_matches_value] = ex_value.present? ? ex_value.to_i : nil

    settings.slice(*API_ALLOWED_TURNITIN_SETTINGS)
  end

  API_ALLOWED_ASSIGNMENT_INPUT_FIELDS = %w(
    name
    clone_of_id
    description
    position
    points_possible
    grading_type
    submission_types
    allowed_extensions
    due_at
    lock_at
    unlock_at
    assignment_group_id
    group_category_id
    peer_reviews
    anonymous_peer_reviews
    peer_reviews_assign_at
    peer_review_count
    automatic_peer_reviews
    external_tool_tag_attributes
    grade_group_students_individually
    turnitin_enabled
    turnitin_settings
    grading_standard_id
    freeze_on_copy
    notify_of_update
    integration_id
    integration_data
  )

  API_ALLOWED_TURNITIN_SETTINGS = %w(
    originality_report_visibility
    s_paper_check
    internet_check
    journal_check
    exclude_biblio
    exclude_quoted
    exclude_small_matches_type
    exclude_small_matches_value
    submit_papers_to
  )

  def update_api_assignment(assignment, assignment_params, user)
    return nil unless assignment_params.is_a?(Hash)

    old_assignment = assignment.new_record? ? nil : assignment.clone
    old_assignment.id = assignment.id if old_assignment.present?

    overrides = deserialize_overrides(assignment_params[:assignment_overrides])
    overrides = [] if !overrides && assignment_params.has_key?(:assignment_overrides)
    assignment_params.delete(:assignment_overrides)

    return if overrides && !overrides.is_a?(Array)
    return false unless valid_assignment_group_id?(assignment, assignment_params)
    return false unless valid_assignment_dates?(assignment, assignment_params)
    return false unless valid_submission_types?(assignment, assignment_params)

    assignment = update_from_params(assignment, assignment_params, user)

    if overrides
      assignment.transaction do
        assignment.save_without_broadcasting!
        batch_update_assignment_overrides(assignment, overrides, user)
      end

      assignment.do_notifications!(old_assignment, assignment_params[:notify_of_update])
    else
      assignment.save!
    end

    return true
    # some values need to be removed before sending the error
  rescue ActiveRecord::RecordInvalid
    return false
  end

  API_ALLOWED_SUBMISSION_TYPES = [
    "online_quiz",
    "none",
    "on_paper",
    "discussion_topic",
    "external_tool",
    "online_upload",
    "online_text_entry",
    "online_url",
    "media_recording",
    "not_graded",
    "wiki_page",
    ""
  ].freeze

  def valid_submission_types?(assignment, assignment_params)
    return true if assignment_params['submission_types'].nil?
    assignment_params['submission_types'] = Array(assignment_params['submission_types'])

    if assignment_params['submission_types'].present? &&
      !assignment_params['submission_types'].all? do |s|
        return false if s == 'wiki_page' && !self.context.try(:feature_enabled?, :conditional_release)
        API_ALLOWED_SUBMISSION_TYPES.include?(s)
      end
        assignment.errors.add('assignment[submission_types]',
          I18n.t('assignments_api.invalid_submission_types',
            'Invalid submission types'))
        return false
    end
    true
  end

  # validate that date and times are iso8601
  def valid_assignment_dates?(assignment, assignment_params)
    errors = ['due_at', 'lock_at', 'unlock_at', 'peer_reviews_assign_at'].map do |v|
      if assignment_params[v].present? && assignment_params[v] !~ Api::ISO8601_REGEX
        assignment.errors.add("assignment[#{v}]",
                              I18n.t("assignments_api.invalid_date_time",
                                     'Invalid datetime for %{attribute}',
                                     attribute: v))
      end
    end

    errors.compact.empty?
  end

  def valid_assignment_group_id?(assignment, assignment_params)
    ag_id = assignment_params["assignment_group_id"].presence
    # if ag_id is a non-numeric string, ag_id.to_i will == 0
    if ag_id and ag_id.to_i <= 0
      assignment.errors.add('assignment[assignment_group_id]', I18n.t(:not_a_number, "must be a positive number"))
      false
    else
      true
    end
  end

  def update_from_params(assignment, assignment_params, user)
    update_params = assignment_params.slice(*API_ALLOWED_ASSIGNMENT_INPUT_FIELDS)

    if update_params.has_key?('peer_reviews_assign_at')
      update_params['peer_reviews_due_at'] = update_params['peer_reviews_assign_at']
      update_params.delete('peer_reviews_assign_at')
    end

    if update_params.include?(:description)
      # Commented because we currently allow ALL users to do the same edit so
      # designers and stuff don't break it (we trust them)
      # unless BeyondZConfiguration.unrestricted_html_users.include?(@current_user.id)
      unless @current_user && @context && @context.respond_to?(:grants_any_right?) && can_do(@context, @current_user, :manage)
        update_params[:description] = Sanitize.clean(update_params[:description], CanvasSanitize::SANITIZE)
      end
    end

    if update_params["submission_types"].is_a? Array
      update_params["submission_types"] = update_params["submission_types"].map do |type|
        # TODO: remove. this was temporary backward support for a hotfix
        type == "online_media_recording" ? "media_recording" : type
      end
      update_params["submission_types"] = update_params["submission_types"].join(',')
    end

    if update_params.has_key?("assignment_group_id")
      ag_id = update_params.delete("assignment_group_id").presence
      assignment.assignment_group = assignment.context.assignment_groups.where(id: ag_id).first
    end

    if update_params.has_key?("group_category_id") && !assignment.group_category_deleted_with_submissions?
      gc_id = update_params.delete("group_category_id").presence
      assignment.group_category = assignment.context.group_categories.where(id: gc_id).first
    end

    if update_params.has_key?("grading_standard_id")
      standard_id = update_params.delete("grading_standard_id")
      if standard_id.present?
        grading_standard = GradingStandard.for(context).where(id: standard_id).first
        assignment.grading_standard = grading_standard if grading_standard
      else
        assignment.grading_standard = nil
      end
    end

    if assignment_params.key? "muted"
      muted = value_to_boolean(assignment_params.delete("muted"))
      if muted
        assignment.mute!
      else
        assignment.unmute!
      end
    end

    if assignment.context.grants_right?(user, :manage_sis)
      data = update_params['integration_data']
      update_params['integration_data'] = JSON.parse(data) if data.is_a?(String)
    else
      update_params.delete('integration_id')
      update_params.delete('integration_data')
    end

    # do some fiddling with due_at for fancy midnight and add to update_params
    if update_params['due_at'].present? && update_params['due_at'] =~ Api::ISO8601_REGEX
      update_params['time_zone_edited'] = Time.zone.name
    end

    if !assignment.context.try(:turnitin_enabled?)
      update_params.delete("turnitin_enabled")
      update_params.delete("turnitin_settings")
    end

    # use Assignment#turnitin_settings= to normalize, but then assign back to
    # hash so that it is written with update_params
    if update_params.has_key?("turnitin_settings")
      turnitin_settings = update_params.delete("turnitin_settings").slice(*API_ALLOWED_TURNITIN_SETTINGS)
      turnitin_settings['exclude_type'] = case turnitin_settings['exclude_small_matches_type']
        when nil; '0'
        when 'words'; '1'
        when 'percent'; '2'
      end
      turnitin_settings['exclude_value'] = turnitin_settings['exclude_small_matches_value']
      assignment.turnitin_settings = turnitin_settings
    end

    # TODO: allow rubric creation

    if update_params.has_key?("description")
      update_params["description"] = process_incoming_html_content(update_params["description"])
    end

    if assignment_params.has_key? "published"
      published = value_to_boolean(assignment_params['published'])
      assignment.workflow_state = published ? 'published' : 'unpublished'
    end

    if assignment_params.has_key? "only_visible_to_overrides"
      assignment.only_visible_to_overrides = value_to_boolean(assignment_params['only_visible_to_overrides'])
    end

    post_to_sis = assignment_params.key?('post_to_sis') ? value_to_boolean(assignment_params['post_to_sis']) : nil
    unless post_to_sis.nil? || !Assignment.sis_grade_export_enabled?(assignment.context)
      assignment.post_to_sis = post_to_sis
    end

    if assignment_params.key?('moderated_grading')
      assignment.moderated_grading = value_to_boolean(assignment_params['moderated_grading'])
    end

    assignment.updating_user = user
    assignment.attributes = update_params
    assignment.infer_times

    assignment
  end

  def submissions_hash(include_params, assignments, submissions_for_user=nil)
    return {} unless include_params.include?('submission')
    has_observed_users = include_params.include?("observed_users")

    subs_list = if submissions_for_user
      assignment_ids = assignments.map(&:id).to_set
      submissions_for_user.select{ |s|
        assignment_ids.include?(s.assignment_id)
      }
    else
      users = current_user_and_observed(include_observed: has_observed_users)
      @context.submissions.
        where(:assignment_id => assignments.map(&:id)).
        for_user(users)
    end

    if has_observed_users
      # assignment id -> array. even if <2 results for a given
      # assignment, we want to consistently return an array when
      # include[]=observed_users was supplied
      hash = Hash.new { |h,k| h[k] = [] }
      subs_list.each { |s| hash[s.assignment_id] << s }
    else
      # assignment id -> specific submission. never return an array when
      # include[]=observed_users was _not_ supplied
      hash = Hash[subs_list.map{|s| [s.assignment_id, s]}]
    end
    hash
  end

  # Returns an array containing the current user.  If
  # include_observed: true is passed also returns any observees if
  # the current user is an observer
  def current_user_and_observed(opts = { include_observed: false })
    user_and_observees = Array(@current_user)
    if opts[:include_observed] && @context_enrollment.observer?
      user_and_observees.concat(ObserverEnrollment.observed_students(@context, @current_user).keys)
    end
    user_and_observees
  end

  private

  def submissions_download_url(context, assignment)
    if assignment.quiz?
      course_quiz_quiz_submissions_url(context, assignment.quiz, zip: 1)
    else
      course_assignment_submissions_url(context, assignment, zip: 1)
    end
  end
end
