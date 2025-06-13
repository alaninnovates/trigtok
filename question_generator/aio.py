import os
import json

from supabase import create_client
from google import genai
from google.genai import types
import dotenv
from pydantic import BaseModel

dotenv.load_dotenv()

client = genai.Client(
    api_key=os.environ.get("GEMINI_API_KEY"),
)
supabase_client = create_client(
    os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_SERVICE_ROLE_KEY")
)
model = "gemini-2.0-flash"

classes_data = json.loads(open("data/classes.json").read())
units_data = json.loads(open("data/units.json").read())
topics_data = json.loads(open("data/topics.json").read())


class MultipleChoiceQuestion(BaseModel):
    stimulus: str
    question: str
    answers: list[str]
    correct_answer: int
    explanations: list[str]


def generate_mcqs(
        class_name: str,
        unit_name: str,
        topic: str,
) -> list[MultipleChoiceQuestion]:
    system_instructions = [
        types.Part.from_text(
            text=f"""You are a test writer for the AP {class_name} Exam.

Your goal is to write 4 realistic multiple choice questions for the provided topic and unit.

Follow these guidelines:
- Write a multiple-choice question that tests deeper conceptual understanding or reasoning, not simple recall
- Provide four answer choices with only one correct answer and several plausible distractors
- Mark the correct answer's index
- Provide a short explanation justifying the correct answer and eliminating the incorrect ones"""
        ),
        types.Part.from_text(
            text=f"""<EXAMPLE>
Input:
    Unit: Unit 3: Development and Learning
    Topic: 3.9 Social, Cognitive, and Neurological Factors in Learning

Output:
{{
  "stimulus": "Oksana experiences pleasurable feelings when she hugs her mother. Recently, her mother started wearing a new perfume, which Oksana can smell when she hugs her mother. When Oksana is shopping, she smells that new perfume near the counter where it is sold. She immediately feels the same pleasurable feelings as she does when she hugs her mother.",
  "question": "In terms of classical conditioning, which of the following is the smell of the new perfume?",
  "answers": [
    "Unconditioned stimulus (UCS)",
    "Conditioned stimulus (CS)",
    "Positive reinforcement",
    "Unconditioned response (UCR)"
  ],
  "correct_answer": 1,
  "explanations": [
    "Incorrect. The unconditioned stimulus is something that naturally causes a response, like the hug itself, not the perfume.",
    "Correct. The perfume, once neutral, becomes associated with the pleasurable feelings and thus is the conditioned stimulus.",
    "Incorrect. Positive reinforcement is an operant conditioning concept, not classical conditioning.",
    "Incorrect. An unconditioned response is a natural reaction, like feeling good from a hug, not the perfume itself."
  ]
}}
</EXAMPLE>
<EXAMPLE>  
Input:  
	Unit: Unit 5: Mental and Physical Health  
	Topic: 5.3 Explaining and Classifying Psychological Disorders  
Output:
{{
"stimulus": "Researchers conducted a study with 200 participants who had been diagnosed with schizophrenia and a comparison group of 200 patients who had not been diagnosed with schizophrenia. The researchers found that participants who had been diagnosed with schizophrenia had significantly larger ventricles than a comparison group. Based on this finding, the researchers concluded that enlarged ventricles cause people to develop schizophrenia.",
"question": "Which of the following most accurately describes why this conclusion is flawed?",
"answers": [
"The researchers’ sample is not large enough to allow researchers to draw any scientific conclusions.",
"The researchers’ results indicate no correlation between the variables.",
"The researchers’ conclusion does not adequately account for the role of GABA in developing schizophrenia.",
"The researchers’ cause-and-effect conclusions cannot be made because no independent variable is manipulated"
],
"correct_answer": 3,
"explanations": [
"Incorrect. A sample of 400 is generally large enough to support basic statistical analysis.",
"Incorrect. The study does show a correlation between enlarged ventricles and schizophrenia, just not causation.",
"Incorrect. While GABA may play a role, the flaw is not about neurotransmitters, but study design.",
"Correct. No variable was manipulated experimentally, so causal conclusions are inappropriate."
]
}}
</EXAMPLE>

<EXAMPLE>  
Input:  
	Unit: Unit 3: Development and Learning  
	Topic: 3.6 Social-Emotional Development Across the Lifespan  
Output:
{{
"stimulus": "Ten primary caregivers of children completed an assessment to determine the degree to which they practice authoritative parenting. The table shows the participants’ scores on this assessment. The lowest possible score is 1, meaning the degree of authoritative parenting is low. The highest possible score is 15, meaning the degree of authoritative parenting is high. Scores: [3, 4, 6, 7, 8, 9, 10, 11, 12, 13]",
"question": "Based on the table, what is the range of the caregivers’ scores?",
"answers": [
"4",
"8",
"9",
"12"
],
"correct_answer": 3,
"explanations": [
"Incorrect. 4 is not the difference between the highest and lowest score.",
"Incorrect. 8 is not the range from 3 to 13.",
"Incorrect. 9 is not the correct calculation of the difference between highest and lowest scores.",
"Correct. The range is the highest score (13) minus the lowest score (1), which equals 12."
]
}}
</EXAMPLE>
<EXAMPLE>
<EXAMPLE>  
Input:  
	Unit: Unit 3: Development and Learning  
	Topic: 3.8 Operant Conditioning  
Output:
{{
"stimulus": "Dr. Trenton conducted a study to determine whether massed practice or distributed practice produced better academic outcomes. He recruited volunteers from a high school Spanish class and randomly assigned students to learn a list of 100 new vocabulary words for which they were later given a word recall test. Students prepared for the word recall test using either distributed practice by studying for 30 minutes a day the week before the test, or massed practice by intensively studying the night before the test.",
"question": "What was the dependent variable in this research project?",
"answers": [
"Massed practice",
"Distributed practice",
"High school students",
"Word recall"
],
"correct_answer": 3,
"explanations": [
"Incorrect. Massed practice is one of the independent variables being manipulated.",
"Incorrect. Distributed practice is also an independent variable being manipulated.",
"Incorrect. The high school students are the participants, not a variable.",
"Correct. Word recall is the outcome being measured, making it the dependent variable."
]
}}
</EXAMPLE>"""
        ),
    ]

    contents = types.Content(
        role="user",
        parts=[
            types.Part.from_text(
                text=f"""Unit: {unit_name}
Topic: {topic}"""
            ),
        ],
    )

    generate_content_config = types.GenerateContentConfig(
        response_mime_type="application/json",
        response_schema=list[MultipleChoiceQuestion],
        system_instruction=system_instructions,
    )

    while True:
        try:
            response = client.models.generate_content(
                model=model,
                contents=contents,
                config=generate_content_config,
            )
            return response.parsed
        except Exception as e:
            print(f"Error: {e}. Retrying...")


class FreeResponseQuestion(BaseModel):
    stimulus: str
    questions: list[str]
    rubric: list[str]


def generate_frqs(
        class_name: str, unit_name: str, topic: str
) -> list[FreeResponseQuestion]:
    system_instructions = [
        types.Part.from_text(
            text=f"""You are a test writer for the {class_name} Exam.

Your task is to write 2 realistic Free Response Questions (FRQ) for the provided topic and unit.

Follow these guidelines:
- Present a realistic, AP-style stimulus that provides context for the questions
- Ask 6 related sub-questions that require students to:
    - Analyze, interpret, or explain key concepts from the topic
    - Apply reasoning or make predictions
    - Use appropriate evidence or data
- Format it clearly and professionally, as it would appear on the AP Exam
- Include a scoring rubric or brief explanation of how each part would be evaluated (what earns credit)
- Use the tone, depth, and expectations of real AP FRQs. Ensure the task demands align with the AP's cognitive rigor.
- Avoid overly simplistic or vague questions that do not require higher-order thinking"""
        ),
        types.Part.from_text(
            text=f"""
<EXAMPLE>
Input:
    Unit: Unit 3: Development and Learning
    Topic: 3.9 Social, Cognitive, and Neurological Factors in Learning

Output:
{{
  "stimulus": "Few large-scale, long-term studies have been conducted to test whether taking a multivitamin makes a difference in improving memory ability as one ages. In this study, researchers examined whether taking a multivitamin slows cognitive decline in later life.\n\nParticipants\nAn earlier study, which was conducted in 2017 and included over 21,000 people, examined the effects of taking a multivitamin on health outcomes. From that study’s sample, over 7,000 people received a mailed invitation to participate in this study. Of those who received the invitation, almost 4,000 participants agreed to participate and were accepted. To be accepted, participants had to be over 65 years of age if women and over 60 years of age if men. In addition, they could not participate if they had ever had a stroke, if they had received a cancer diagnosis in the two years before the study, or if they had a history of any other serious illnesses. Participants had to be able to communicate in English and have access to an Internet-connected computer.\n\nA computer randomly assigned participants to two groups. Participants in Group 1 received a pack of multivitamins each month by mail to take one pill twice a day. Participants in Group 2 received a pack of placebo pills in the same type of packaging as Group 1 and with the same instructions. The sample size of Group 1 was 1,758 people, and the sample size of Group 2 was 1,804 people. The demographics of each group are listed in the table:\n\nDemographic         | Group 1 – Multivitamin | Group 2 – Placebo\n-------------------|------------------------|------------------\nAge (Mean, SD)     | 70.9 (4.5)             | 71.0 (4.6)\nMen                | 32.9%                  | 33.4%\nWomen              | 67.1%                  | 66.6%\nWhite              | 93.1%                  | 93.5%\nAfrican American   | 2.3%                   | 2.6%\nHispanic           | 1.5%                   | 1.4%\nOther/Multiple     | 1.8%                   | 1.2%\nAsian/NH           | 0.2%                   | 0.1%\nAmerican Indian    | 1.1%                   | 1.2%\n\nMethod\nOnce a year for 3 years, participants were asked to complete an online test to evaluate episodic memory and executive functioning. Instructions on how to access the test materials were emailed to participants, and participants who responded to the email indicated their consent. The participants received a $15 gift card for each annual assessment, regardless of completion.\n\nThe multivitamin used is widely available in the United States. Side effects of taking the multivitamin include low rates of stomach pain, diarrhea, skin rash, bruising, and an increased rate of gastrointestinal bleeding, which are considered normal side effects for those taking a multivitamin in the general population.\n\nTwo different tasks were used to measure episodic memory and executive functioning in this study:\n- Episodic Memory: Participants completed a recall task in which they were first shown a set of words, presented one at a time for three seconds each. They were then asked to recall the set of words, once immediately after the word list was presented and again after 15 minutes had passed. Participants who recalled more words correctly earned higher scores.\n- Executive Functioning: Participants were first shown one set of items and were then shown a second set. They were asked to identify whether items in the second set were the same as or different from the first. Participants earned higher scores the more quickly they correctly identified the match or difference.\n\nResults and Discussion\nCompared with participants taking a placebo, participants receiving the multivitamin had significantly greater improvement in the recall task at the end of the first year. Performance on the immediate recall memory task in Group 1 improved from a mean of 7.10 words at baseline to 7.81 words after 1 year of taking the multivitamin, an improvement mean of 0.71. In Group 2, which received the placebo pills, performance improved from 7.21 words at baseline to 7.65 words, an improvement mean of 0.44. When comparing the multivitamin group with the placebo group averaged across all 3 years of intervention, findings suggest that the memory improvement is sustained over time. \n\nResearchers estimate that the effect of the multivitamin intervention improved memory performance in participants in the multivitamin group by the equivalent of 3.1 years of age-related memory change compared to participants in the placebo group. Researchers also found that executive functioning was not significantly impacted by taking a multivitamin.\n\nThe findings suggest that the greatest benefit to taking a multivitamin is found in immediate memory recall, something especially vulnerable in aging adults.",
  "questions": [
    "Identify the research method used in the study.",
    "State the operational definition of executive functioning.",
    "Describe what the difference in means indicates for the immediate recall task for the multivitamin group as compared to the placebo group.",
    "Identify at least one ethical guideline applied by the researchers.",
    "Explain the extent to which the research findings may or may not be generalizable using specific and relevant evidence from the study.",
    "Explain how at least one of the research findings supports or refutes the researchers’ hypothesis that taking a multivitamin slows cognitive decline in later life."
  ],
  "rubric": [
    "One point for correctly identifying the research method as a randomized controlled experiment or randomized clinical trial.",
    "One point for stating that executive functioning was measured by how quickly and accurately participants identified whether items in the second set matched or differed from items in the first set.",
    "One point for stating that the multivitamin group showed greater improvement in immediate recall (mean increase of 0.71 vs. 0.44) indicating a greater effect of multivitamin on memory performance.",
    "One point for identifying an ethical guideline such as informed consent (participants responded via email to indicate consent) or minimal risk (side effects were normal for the general population).",
    "One point for discussing generalizability, e.g., limited due to lack of diversity (over 93% White) or strong because of large sample size and random assignment.",
    "One point for explaining that the finding of improved immediate recall in the multivitamin group supports the hypothesis that multivitamins slow cognitive decline."
  ]
}}
</EXAMPLE>"""
        ),
    ]

    contents = [
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(
                    text=f"""Unit: {unit_name}
Topic: {topic}"""
                ),
            ],
        ),
    ]

    generate_content_config = types.GenerateContentConfig(
        response_mime_type="application/json",
        response_schema=list[FreeResponseQuestion],
        system_instruction=system_instructions,
    )

    while True:
        try:
            response = client.models.generate_content(
                model=model,
                contents=contents,
                config=generate_content_config,
            )
            return response.parsed
        except Exception as e:
            print(f"Error: {e}. Retrying...")


def mcq_gen(class_name: str,
            unit_name: str,
            unit_id: int,
            unit_number: int,
            ):
    to_insert = []
    for topic in filter(lambda t: t["unit_id"] == unit_id, topics_data):
        print(f"Topic: {topic}")
        should_retry = True
        while should_retry:
            mcq_response = generate_mcqs(
                class_name=class_name,
                unit_name=f"Unit {unit_number}: {unit_name}",
                topic=topic["topic"],
            )
            if not mcq_response:
                print("No MCQs generated, retrying...")
                continue
            print("Generated")
            to_insert.extend(
                [
                    {
                        "stimulus": q.stimulus,
                        "question": q.question,
                        "answers": q.answers,
                        "correct_answer": q.correct_answer,
                        "explanations": q.explanations,
                        "unit_id": unit_id,
                        "topic": topic["id"],
                    }
                    for q in mcq_response
                ]
            )
            should_retry = False
    supabase_client.table("multiple_choice_questions").insert(to_insert).execute()


def frq_gen(class_name: str,
            unit_name: str,
            unit_id: int,
            unit_number: int,
            ):
    to_insert = []
    for topic in filter(lambda t: t["unit_id"] == unit_id, topics_data):
        print(f"Topic: {topic}")
        should_retry = True
        while should_retry:
            frq_response = generate_frqs(
                class_name=class_name,
                unit_name=f"Unit {unit_number}: {unit_name}",
                topic=topic["topic"],
            )
            if not frq_response:
                print("No FRQs generated, retrying...")
                continue
            print("Generated")
            to_insert.extend(
                [
                    {
                        "stimulus": q.stimulus,
                        "questions": [{"text": qu, "point_value": 1} for qu in q.questions],
                        "rubric": q.rubric,
                        "unit_id": unit_id,
                        "topic": topic["id"],
                        "total_points": len(q.questions),
                    }
                    for q in frq_response
                ]
            )
            should_retry = False
    supabase_client.table("free_response_questions").insert(to_insert).execute()


def process_class(class_id: int):
    class_data = next((c for c in classes_data if c["id"] == class_id), None)
    class_name = class_data["name"]
    for unit in filter(lambda u: u["class_id"] == class_id, units_data):
        unit_id = unit["id"]
        unit_name = unit["name"]
        unit_number = unit["number"]
        print(f"Generating for {class_name} - {unit_number} {unit_name}")
        frq_gen(
            class_name=class_name,
            unit_name=unit_name,
            unit_id=unit_id,
            unit_number=unit_number,
        )


def main():
    process_class(12)


if __name__ == "__main__":
    main()
