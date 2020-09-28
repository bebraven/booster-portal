class CreateProjectScores140Table < ActiveRecord::Migration
  tag :predeploy
  def change
    orig_column_names = ["Student ID", "Student Name", "Student Email", "Total Score -- Capstone Challenge", "Category 1 Average -- Capstone Challenge", "Category 2 Average -- Capstone Challenge", "Category 3 Average -- Capstone Challenge", "1.1. Presenters identify users’ needs based in their own empathy research. -- Capstone Challenge", "1.2. Presenters clearly define the problem. -- Capstone Challenge", "1.3. Presenters explain why it is important to address the problem. -- Capstone Challenge", "1.4. Presenters pitch their top design solution and explain how their prototype solves the given problem. -- Capstone Challenge", "1.5. Presenters describe the feedback they received when testing their prototype and how they iterated to improve the prototype. -- Capstone Challenge", "1.6. Design solution is original and provides a unique value-add unlike other solutions that have been built. -- Capstone Challenge", "1.7.\tDesign solution is feasible. -- Capstone Challenge", "1.8. Presenters describe what realistic, specific next steps they will take to implement their solution. -- Capstone Challenge", "2.1. Language and posture match the level of formality and demonstrate positivity, curiosity, respect and humility. -- Capstone Challenge", "2.10. Fellows do not read from slides/notes or sound robotic. -- Capstone Challenge", "2.11. I feel connected to the presenters and/or the content (e.g., through compelling data, use of story, or other techniques to connect to the audience). -- Capstone Challenge", "2.2. Presentation opens with a team introduction, including names, Braven cohort, and closes by thanking the audience and evaluators. -- Capstone Challenge", "2.3. Presentation opens with an engaging hook to grab the audience's attention. -- Capstone Challenge", "2.4. Presentation tells a story of the overall arc of the cohort's design thinking process - where did the cohort start, what did it work through, and where did it end? -- Capstone Challenge", "2.5. All presenters are dressed appropriately in business casual attire (no jeans). -- Capstone Challenge", "2.6. All cohort members contribute to the presentation (e.g. Clearly planned roles). -- Capstone Challenge", "2.7. Presenters speak with minimal verbal tics and fillers. -- Capstone Challenge", "2.8. The presentation concludes with a clear, final summary of the main points. -- Capstone Challenge", "2.9. The presentation does not exceed 7 minutes. -- Capstone Challenge", "3.1 No spelling or grammatical errors. -- Capstone Challenge", "3.2 Color and font choices are consistent throughout. -- Capstone Challenge", "3.3 Formatting is consistent throughout (e.g. Title capitalization, use and positioning of bullets, consistency with left vs. center justification, alignment of figures, etc.) -- Capstone Challenge", "3.4 Slides are not crowded with text or images. -- Capstone Challenge", "3.5. The slides support the oral presentation by effectively visualizing the spoken content. -- Capstone Challenge", "Total Score -- Capstone Challenge: Teamwork", "Category 4 Average -- Capstone Challenge: Teamwork", "4.1 Actively contributed to team success. -- Capstone Challenge: Teamwork", "4.2 Met deadlines and fulfilled responsibilities in a timely manner. -- Capstone Challenge: Teamwork", "4.3 Gave feedback to others to help them be more successful and productive. -- Capstone Challenge: Teamwork", "4.4 Embraced different perspectives on the team with openness and a sense of possibility. -- Capstone Challenge: Teamwork", "Total Score -- Complete your 1:1 with your Leadership Coach", "Total Score -- Course Participation - Ace your Interviews", "Total Score -- Course Participation - Apply for a Job", "Total Score -- Course Participation - Capstone Challenge Kickoff", "Total Score -- Course Participation - Discover Your Career Path", "Total Score -- Course Participation - Empathize", "Total Score -- Course Participation - Ideate & Prototype", "Total Score -- Course Participation - Lead Authentically", "Total Score -- Course Participation - Live Your Legacy", "Total Score -- Course Participation - Network Like a Pro", "Total Score -- Course Participation - Polish Your Portfolio", "Total Score -- Course Participation - Present Effectively", "Total Score -- Course Participation - Synthesize", "Total Score -- Course Participation - Tell Your Story", "Total Score -- Design Your Career Project", "Category 1 Average -- Design Your Career Project", "Category 2 Average -- Design Your Career Project", "1.1 Collects a significant amount of stories from people. -- Design Your Career Project", "1.10 Fellow is the protagonist of the story. -- Design Your Career Project", "1.11 Completes hustle statement. -- Design Your Career Project", "1.2 Summarizes the stories people told. -- Design Your Career Project", "1.3 Identifies strengths apparent in stories. -- Design Your Career Project", "1.4 Writes a narrative about strengths grounded in real examples. -- Design Your Career Project", "1.5 Narrative is compelling, cohesive, and well-organized. -- Design Your Career Project", "1.6 Narrative is free of spelling or grammatical errors. -- Design Your Career Project", "1.7 Employs the PAR (problem, action, result) framework of storytelling. -- Design Your Career Project", "1.8 Communicates value(s) and problem, action, and result through the story by showing, not telling. -- Design Your Career Project", "1.9 Includes details to make stories visual and memorable. -- Design Your Career Project", "2.1 Creates a comprehensive backwards plan. -- Design Your Career Project", "2.2 Creates a logical, ambitious, and realistic timeline. -- Design Your Career Project", "2.3 Identifies specific entry-level role (title and web link). -- Design Your Career Project", "2.4 Completes description analysis of entry-level role to identify skills they need to build. -- Design Your Career Project", "2.5 College Roadmap: Identifies accomplishments to date. -- Design Your Career Project", "2.6 College Roadmap: Creates big goals that will lead to a career-accelerating opportunity. -- Design Your Career Project", "2.7 College Roadmap: Creates milestones that will help Fellow stay on track towards big goals. -- Design Your Career Project", "Total Score -- Hustle to Career Project", "Category 1 Average -- Hustle to Career Project", "Category 2 Average -- Hustle to Career Project", "Category 3 Average -- Hustle to Career Project", "Category 4 Average -- Hustle to Career Project", "1.1 Develops a professional online brand through LinkedIn profile. -- Hustle to Career Project", "1.10 Email includes all the necessary components to make it strong. -- Hustle to Career Project", "1.11 Email is professional and concise. -- Hustle to Career Project", "1.12 Elevator pitch includes all necessary components. -- Hustle to Career Project", "1.13 Pitches self in a compelling and influential way. -- Hustle to Career Project", "1.14 Email is free of spelling and grammatical errors. -- Hustle to Career Project", "1.15 Conducts two informational interviews. -- Hustle to Career Project", "1.16 Plans how to leverage this connection. -- Hustle to Career Project", "1.17 Reflects meaningfully on the informational interviews with a growth mindset. -- Hustle to Career Project", "1.18 Plans how to leverage new contacts. -- Hustle to Career Project", "1.19 Reflects meaningfully on the event with a growth mindset. -- Hustle to Career Project", "1.2 Writes a LinkedIn profile summary that includes all the necessary components. -- Hustle to Career Project", "1.3 Writes a strong, compelling LinkedIn summary that invites people to get in touch with you. -- Hustle to Career Project", "1.4 Completes education section of profile. -- Hustle to Career Project", "1.5 Completes experience section of profile. -- Hustle to Career Project", "1.6 Includes skills and endorsements on profile. -- Hustle to Career Project", "1.7 Develops extensive professional network on LinkedIn. -- Hustle to Career Project", "1.8 Makes an effort to set apart from the crowd. -- Hustle to Career Project", "1.9 Profile is free of spelling and grammatical errors. -- Hustle to Career Project", "2.1 Identifies three opportunities. -- Hustle to Career Project", "2.10 Highlights impact in Experience section. -- Hustle to Career Project", "2.11 Includes Braven Accelerator or other leadership experience on resume. -- Hustle to Career Project", "2.12 Completes extra sections of resume as needed. -- Hustle to Career Project", "2.13 Resume is free of spelling and grammatical errors. -- Hustle to Career Project", "2.14 Proactively seeks feedback on resume. -- Hustle to Career Project", "2.2 Identifies the requirements of the opportunity and ensures is qualified for the role. -- Hustle to Career Project", "2.3 Fills one page. -- Hustle to Career Project", "2.4 Formats resume professionally. -- Hustle to Career Project", "2.5 Completes Education section of resume. -- Hustle to Career Project", "2.6 Completes Experience section of resume. -- Hustle to Career Project", "2.7 Includes relevant coursework  and projects. -- Hustle to Career Project", "2.8 All other experiences (other than coursework and projects) included are relevant and demonstrate commitment. -- Hustle to Career Project", "2.9 Presents bulleted lists with strong action verbs under each experience. -- Hustle to Career Project", "3.1. Formats the cover letter professionally. -- Hustle to Career Project", "3.2 Cover letter is compelling. -- Hustle to Career Project", "3.3 Completes a salutation and introduction to the cover letter. -- Hustle to Career Project", "3.4 Uses the body of the cover letter to convince the reader of qualification for and interest in the specific role. -- Hustle to Career Project", "3.5 Completes a closing for the cover letter. -- Hustle to Career Project", "3.6 Cover letter is free of spelling and grammatical errors. -- Hustle to Career Project", "4.1 Responds to the \"Tell me about yourself\" question with compelling experience about fit for role. -- Hustle to Career Project", "4.2 Responds to the \"Tell me about yourself\" question concisely and with focus. -- Hustle to Career Project", "4.3 Speaks with professional polish while answering the \"Tell me about yourself\" question. -- Hustle to Career Project", "4.4 Participates in mock interviews with professionals. -- Hustle to Career Project", "4.5 Writes a heartfelt thank you email to interviewer. -- Hustle to Career Project", "4.6 Thank you email is free of spelling and grammatical errors. -- Hustle to Career Project", "4.7 Reflects meaningfully on the interviews with a growth mindset. -- Hustle to Career Project", "Total Score -- Learning Lab 10 Impact Survey", "Total Score -- Learning Lab 11 Impact Survey", "Total Score -- Learning Lab 12 Impact Survey", "Total Score -- Learning Lab 13 Impact Survey", "Total Score -- Learning Lab 14 Impact Survey", "Total Score -- Learning Lab 15 Impact Survey", "Total Score -- Learning Lab 2 Impact Survey", "Total Score -- Learning Lab 3 Impact Survey", "Total Score -- Learning Lab 4 Impact Survey", "Total Score -- Learning Lab 5 Impact Survey", "Total Score -- Learning Lab 6 Impact Survey", "Total Score -- Learning Lab 7 Impact Survey", "Total Score -- Learning Lab 8 Impact Survey", "Total Score -- Learning Lab 9 Impact Survey", "Total Score -- Post-Accelerator Survey", "Total Score -- Pre-Accelerator Survey", "Total Score -- Revised Resume Project", "Category 1 Average -- Revised Resume Project", "Category 2 Average -- Revised Resume Project", "1.1 Adds Capstone Challenge to resume as meaningful accomplishment. -- Revised Resume Project", "1.10 Completes extra sections of resume as needed. -- Revised Resume Project", "1.11 Resume is free of spelling and grammatical errors. -- Revised Resume Project", "1.12 Meaningfully reflects on how incorporated feedback and improved resume. -- Revised Resume Project", "1.2 Fills one page. -- Revised Resume Project", "1.3 Formats resume professionally. -- Revised Resume Project", "1.4 Completes Education section of resume. -- Revised Resume Project", "1.5 Completes Experience section of resume. -- Revised Resume Project", "1.6 Includes relevant coursework  and projects. -- Revised Resume Project", "1.7 All other experiences (other than coursework and projects) included are relevant and demonstrate commitment. -- Revised Resume Project", "1.8 Presents bulleted lists with strong action verbs under each experience. -- Revised Resume Project", "1.9 Highlights impact in Experience section. -- Revised Resume Project", "2.1 Knows him/herself and what is important to him/her. -- Revised Resume Project", "2.2 Explains impact Braven had on him/her. -- Revised Resume Project", "2.3 Describes the kind of impact s/he wants to have on others. -- Revised Resume Project", "2.4 Determines what s/he will do in life. -- Revised Resume Project", "2.5 Engages meaningfully with reflection. -- Revised Resume Project"]

    create_table :course140_project_scores do |t|
      orig_column_names.each do |col_name|

        new_name = col_name.downcase.gsub(/[^0-9a-z]/, '_').to_sym
        if ['Student Name', 'Student Email'].member? col_name then
          t.string new_name
        else
          t.integer new_name
        end
      end
    end
  end
end