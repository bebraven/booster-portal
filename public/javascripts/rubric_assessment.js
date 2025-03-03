/**
 * Copyright (C) 2011 Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
define([
  'i18n!rubric_assessment',
  'jquery' /* $ */,
  'str/htmlEscape',
  'compiled/str/TextHelper',
  'compiled/util/round',
  'jquery.instructure_forms' /* fillFormData */,
  'jqueryui/dialog',
  'jquery.instructure_misc_plugins' /* showIf */,
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */
], function(I18n, $, htmlEscape, TextHelper, round) {

// TODO: stop managing this in the view and get it out of the global scope submissions/show.html.erb
window.rubricAssessment = {
  init: function(){
    var $rubric_criterion_comments_dialog = $("#rubric_criterion_comments_dialog");

    $('.rubric')
      .delegate(".rating", 'click', function(event) {
        $(this).parents(".criterion").find(".criterion_points").val($(this).find(".points").text()).change();
      })
      .delegate(".long_description_link", 'click', function(event) {
        event.preventDefault();
        if(!$(this).parents(".rubric").hasClass('editing')) {
          var data = $(this).parents(".criterion").getTemplateData({textValues: ['long_description', 'description']}),
              is_learning_outcome = $(this).parents(".criterion").hasClass("learning_outcome_criterion");
          $("#rubric_long_description_dialog")
            .fillTemplateData({data: data, htmlValues: ( is_learning_outcome ? ['long_description'] : [] )})
            .find(".editing").hide().end()
            .find(".displaying").show().end()
            .dialog({
              title: I18n.t('titles.criterion_long_description', "Criterion Long Description"),
              width: 400
            });
        }
      })
      .delegate(".criterion .saved_custom_rating", 'change', function() {
        if($(this).parents(".rubric").hasClass('assessing')) { 
          var val = $(this).val();
          if(val && val.length > 0) {
            $(this).parents(".custom_ratings_entry").find(".custom_rating_field").val(unescape(val));
          }
        }
      })
      .delegate('.criterion_comments_link', 'click', function(event) {
        event.preventDefault();
        var $rubric_criterion_comments_link = $(this);
        var $criterion = $(this).parents(".criterion");
        var comments = $criterion.getTemplateData({textValues: ['custom_rating']}).custom_rating;
        var editing = $(this).parents('.rubric.assessing').length > 0;
        var data = {
          criterion_comments: comments,
          criterion_description: $criterion.find(".description:first").text()
        };

        $rubric_criterion_comments_dialog.data('current_rating', $criterion);
        $rubric_criterion_comments_dialog.fillTemplateData({data: data});
        $rubric_criterion_comments_dialog.fillFormData(data);
        $rubric_criterion_comments_dialog.find(".editing").showIf(editing);
        $rubric_criterion_comments_dialog.find(".displaying").showIf(!editing);
        $rubric_criterion_comments_dialog.dialog({
          title: I18n.t('titles.additional_comments', "Additional Comments"),
          width: 400,
          close: function() {
            $rubric_criterion_comments_link.focus();
          }
        });
        $rubric_criterion_comments_dialog.find("textarea.criterion_comments").focus();
      })
      // cant use a .delegate because up above when we delegate '.rating' 'click' it calls .change() and that doesnt bubble right so it doesen't get caught
      .find(".criterion_points").bind('keyup change blur', function(event) {
        var $obj = $(event.target);
        if($obj.parents(".rubric").hasClass('assessing')) {
          var val = parseFloat($obj.val(), 10);
          if(isNaN(val)) { val = null; }
          var $criterion = $obj.parents(".criterion");
          $criterion.find(".rating.selected").removeClass('selected');
          if (val || val === 0) {
            $criterion.find(".criterion_description").addClass('completed');
            $criterion.find(".rating").each(function() {
              var rating_val = parseFloat($(this).find(".points").text(), 10);
              if(rating_val == val) {
                $(this).addClass('selected');
              }
            });
          } else {
            $criterion.find(".criterion_description").removeClass('completed');
          }
          var total = 0;
          $obj.parents(".rubric").find(".criterion:visible:not(.ignore_criterion_for_scoring) .criterion_points").each(function() {
            var val = parseFloat($(this).val(), 10);
            if(isNaN(val)) { val = 0; }
            total += val;
          });
          total = round(total, round.DEFAULT)
          $obj.parents(".rubric").find(".rubric_total").text(total);
        }
      });

    $(".rubric_summary").delegate(".rating_comments_dialog_link", 'click', function(event) {
      event.preventDefault();
      var $rubric_rating_comments_link = $(this);
      var $criterion = $(this).parents(".criterion");
      var comments = $criterion.getTemplateData({textValues: ['rating_custom']}).rating_custom;
      var data = {
        criterion_comments: comments,
        criterion_description: $criterion.find(".description_title:first").text()
      };

      $rubric_criterion_comments_dialog.data('current_rating', $criterion);
      $rubric_criterion_comments_dialog.fillTemplateData({data: data});
      $rubric_criterion_comments_dialog.fillFormData(data);
      $rubric_criterion_comments_dialog.find(".editing").hide();
      $rubric_criterion_comments_dialog.find(".displaying").show();
      $rubric_criterion_comments_dialog.dialog({
        title: I18n.t('titles.additional_comments', "Additional Comments"),
        width: 400,
        close: function() {
          $rubric_rating_comments_link.focus();
        }
      });
      $rubric_criterion_comments_dialog.find(".criterion_description").focus();
    });

    $rubric_criterion_comments_dialog.find(".save_button").click(function(event) { 
      var comments   = $rubric_criterion_comments_dialog.find("textarea.criterion_comments").val(),
          $criterion = $rubric_criterion_comments_dialog.data('current_rating');
      if($criterion) {
        $criterion.find(".custom_rating").text(comments);
        $criterion.find(".criterion_comments").toggleClass('empty', !comments);
      }
      $rubric_criterion_comments_dialog.dialog('close');
    });

    $rubric_criterion_comments_dialog.find(".cancel_button").click(function(event) {
      $rubric_criterion_comments_dialog.dialog('close');
    });

    setInterval(rubricAssessment.sizeRatings, 2500);
  },

  sizeRatings: function() {
    var $visibleCriteria = $(".rubric .criterion:visible");
    if ($visibleCriteria.length) {
      var scrollTop = $.windowScrollTop();
      $(".rubric .criterion:visible").each(function() {
        var $this = $(this),
            $ratings = $this.find(".ratings:visible");
        if($ratings.length) {
          var $ratingsContainers = $ratings.find('.rating .container').css('height', ""),
              maxHeight = Math.max(
                $ratings.height(),
                $this.find(".criterion_description .container").height()
              );
          // the -10 here is the padding on the .container.
          $ratingsContainers.css('height', (maxHeight - 10) + 'px');
        }
      });
      //$("html,body").scrollTop(scrollTop);
    }
  },

  assessmentData: function($rubric) {
    $rubric = rubricAssessment.findRubric($rubric);
    var data = {};
    data['rubric_assessment[user_id]'] = ENV.RUBRIC_ASSESSMENT.assessment_user_id || $rubric.find(".user_id").text();
    data['rubric_assessment[assessment_type]'] = ENV.RUBRIC_ASSESSMENT.assessment_type || $rubric.find(".assessment_type").text();
    $rubric.find(".criterion:not(.blank)").each(function() {
      var id = $(this).attr('id');
      var pre = "rubric_assessment[" + id + "]";
      var points = $(this).find(".criterion_points").val();
      data[pre + "[points]"] = !isNaN(points) ? points : undefined
      if($(this).find(".rating.selected")) {
        data[pre + "[description]"] = $(this).find(".rating.selected .description").text();
        data[pre + "[comments]"] = $(this).find(".custom_rating").text();
      }
      if($(this).find(".custom_rating_field:visible").length > 0) {
        data[pre + "[comments]"] = $(this).find(".custom_rating_field:visible").val();
        data[pre + "[save_comment]"] = $(this).find(".save_custom_rating").attr('checked') ? "1" : "0";
      }
    });
    return data;
  },

  findRubric: function($rubric) {
    if(!$rubric.hasClass('rubric')) {
      $new_rubric = $rubric.closest('.rubric');
      if($new_rubric.length === 0) {
        $new_rubric = $rubric.find('.rubric:first');
      }
      $rubric = $new_rubric;
    }
    return $rubric;
  },

  updateRubricAssociation: function($rubric, data) {
    var summary_data = data.summary_data;
    if (summary_data && summary_data.saved_comments) {
      for(var id in summary_data.saved_comments) {
        var comments = summary_data.saved_comments[id],
            $holder = $rubric.find("#criterion_" + id).find(".saved_custom_rating_holder").hide(),
            $saved_custom_rating = $holder.find(".saved_custom_rating");

        $saved_custom_rating.find(".comment").remove();
        $saved_custom_rating.empty().append('<option value="">' + htmlEscape(I18n.t('options.select', '[ Select ]')) + '</option>');
        for(var jdx in comments) {
          if(comments[jdx]) {
            $saved_custom_rating.append('<option value="' + htmlEscape(comments[jdx])+ '">' + htmlEscape(TextHelper.truncateText(comments[jdx], {max: 50})) + '</option>');
            $holder.show();
          }
        }
      }
    }
  },

  populateRubric: function($rubric, data) {
    $rubric = rubricAssessment.findRubric($rubric);
    var id = $rubric.attr('id').substring(7);
    $rubric.find(".user_id").text(ENV.RUBRIC_ASSESSMENT.assessment_user_id || data.user_id).end()
      .find(".assessment_type").text(ENV.RUBRIC_ASSESSMENT.assessment_type || data.assessment_type);

    $rubric.find(".criterion_description").removeClass('completed').removeClass('original_completed').end()
      .find(".rating").removeClass('selected').removeClass('original_selected').end()
      .find(".rating").removeClass('sr_selected_indicator').end()
      .find(".custom_rating_field").val("").end()
      .find(".custom_rating_comments").text("").end()
      .find(".criterion_points").val("").change().end()
      .find(".criterion_rating_points").text("").end()
      .find(".custom_rating").text("").end()
      .find(".save_custom_rating").attr('checked', false);
    $rubric.find(".criterion_comments").addClass('empty');
    if(data) {
      var assessment = data;
      var total = 0;
      for(var idx in assessment.data) {
        var rating = assessment.data[idx];
        var comments = rating.comments_enabled ? rating.comments : rating.description;
        if (rating.comments_enabled && rating.comments_html) {
          var comments_html = rating.comments_html;
        } else {
          var comments_html = htmlEscape(comments);
        }
        var $criterion = $rubric.find("#criterion_" + rating.criterion_id);
        if(!rating.id) {
          $criterion.find(".rating").each(function() {
            var rating_val = parseFloat($(this).find(".points").text(), 10);
            if(rating_val == rating.points) {
              rating.id = $(this).find(".rating_id").text();
            }
          });
        }
        $criterion
          .find(".custom_rating_field").val(comments).end()
          .find(".custom_rating_comments").html(comments_html).end()
          .find(".criterion_points").val(rating.points).change().end()
          .find(".criterion_rating_points_holder").showIf(rating.points || rating.points === 0).end()
          .find(".criterion_rating_points").text(rating.points).end()
          .find(".custom_rating").text(comments).end()
          .find(".criterion_comments").toggleClass('empty', !comments).end()
          .find(".save_custom_rating").attr('checked', false);
        if(ratingHasScore(rating)){
          $criterion
            .find(".criterion_description").addClass('original_completed').end()
            .find("#rating_" + rating.id).addClass('original_selected').addClass('selected').end()
            if($criterion.find("#rating_" + rating.id).find(".sr_selected_indicator").length === 0) {
              $criterion.find("#rating_" + rating.id).append('<span class="sr_selected_indicator sr-only" aria-live="assertive" class="sr-only">selected</span>').end()
            }
        }
        if(comments) $criterion.find('.criterion_comments').show();
        if(rating.points && !rating.ignore_for_scoring) {
          total += rating.points;
        }
      }
      total = round(total, round.DEFAULT)
      $rubric.find(".rubric_total").text(total);
    }
  },

  populateRubricSummary: function($rubricSummary, data) {
    $rubricSummary.find(".criterion_points").text("").end()
      .find(".rating_custom").text("");

    if(data) {
      var assessment = data;
      var total = 0;
      for(var idx in assessment.data) {
        var rating = assessment.data[idx];
        $rubricSummary.find("#criterion_" + rating.criterion_id)
          .find(".rating").hide().end()
          .find(".rating_" + rating.id).show().end()
          .find(".criterion_points").text(rating.points).end()
          .find(".ignore_for_scoring").showIf(rating.ignore_for_scoring);
        if(ratingHasScore(rating) && !$rubricSummary.hasClass('free_form')){
          $rubricSummary.find("#criterion_" + rating.criterion_id)
            .find(".rating.description").show().text(rating.description).end()
        }
        if(rating.comments_enabled && rating.comments) {
          $rubricSummary.find("#criterion_" + rating.criterion_id).find(".rating_custom").show().text(rating.comments);
        }
        if(rating.points && !rating.ignore_for_scoring) {
          total += rating.points;
        }
      }
      total = round(total, round.DEFAULT)
      $rubricSummary.show().find(".rubric_total").text(total);
      $rubricSummary.closest(".edit").show();
    }
    else {
      $rubricSummary.hide();
    }
  }
};

function ratingHasScore(rating) {
  return (rating.points || rating.points === 0);
}

$(rubricAssessment.init);

return rubricAssessment;
});
