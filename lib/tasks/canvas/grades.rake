require 'pry'

namespace :canvas do
  namespace :grades do
    desc 'Alter module grades if the calculated grade is higher'
    task :audit_course, [:course_id] => :environment do |t,args|
      course = Course.find args[:course_id]

      module_titles = [
       "Lead Authentically",
       "NLU Lead Authentically",
       "Tell Your Story", 
       "Discover Your Career Path", 
       "Network Like a Pro",
       "Apply for a Job",
       "Polish Your Portfolio",
       "Ace your Interviews",
       "Capstone Kickoff", 
       "Empathize", 
       "Synthesize", 
       "Ideate & Prototype", 
       "Present Effectively", 
       "Live Your Legacy" 
      ]

      module_item_ids = ContentTag.where(id: course.sequential_module_item_ids, 
                                         title: module_titles).
                                   map(&:id)
                                   
      bzg = BZGrading.new
      fudge = 0.001

      discrepancies = []
      zeros = []

      module_item_ids.each do |module_item_id|
        course.students.each do |student|

          cm = bzg.get_context_module(module_item_id)
          submission = bzg.get_participation_assignment(cm.course, cm).find_or_create_submission(student)

          obj = bzg.calculate_user_module_score(module_item_id, student)
          score = obj['total_score']

          due_date = submission.cache_due_date
          overdue = due_date.past?

          if submission.present? && overdue

            obj['total_score'] = 0

            zero_out = {
              user_id: student.id,
              name: student.sortable_name
            }

            zeros << zero_out
            zeros
            bzg.set_user_grade_for_module(module_item_id, student, obj['total_score'])

            binding.pry

          elsif score > (submission.score + fudge)

            discrepancy = {
              user_id: student.id,
              name: student.sortable_name,
              shown_grade: submission.score,
              calculated: obj['total_score']
            }

            discrepancies << discrepancy
            discrepancies
            bzg.set_user_grade_for_module(module_item_id, student, score)

            binding.pry
          else 
            break
          end

        end 
      end
    end 
  end 
end
