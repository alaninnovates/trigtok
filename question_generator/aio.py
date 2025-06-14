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
- Provide four answer choices with only one correct answer and 3 plausible distractors
- Mark the correct answer's index
- Provide a short explanation justifying the correct answer and eliminating the incorrect ones"""
        ),
        types.Part.from_text(
            text=f"""<EXAMPLE>  
Input:  
	Unit: Unit 3: Period 3: 1754–1800  
	Topic: 3.2 The Seven Years’ War (The French and Indian War)
  
Output:
{{
  "stimulus": "“May it . . . please your most excellent Majesty, that it may be declared . . . in this present parliament assembled, and by the authority of the same, That the said colonies and plantations in America have been, are, and of right ought to be, subordinate unto, and dependent upon the imperial crown and parliament of Great Britain; . . . and [they] of right ought to have, full power and authority to make laws and statutes of sufficient force and validity to bind the colonies and people of America, subjects of the crown of Great Britain, in all cases whatsoever.”\nThe Declaratory Act, passed by the British Parliament in 1766",
  "question": "Which of the following contributed most directly to the enactment of the law in the excerpt?",
  "answers": [
    "The increasing divergence between colonial and British culture in the 1700s",
    "Debates over how Britain’s colonies should bear the cost of the Seven Years’ War (French and Indian War)",
    "The drafting of a declaration of independence for Britain’s colonies in North America",
    "Conflicts between colonists and British army leaders over recognizing Native American sovereignty"
  ],
  "correct_answer": 1,
  "explanations": [
    "Incorrect. While cultural divergence existed, it was not the immediate cause of the Declaratory Act, which was passed in response to political and financial issues.",
    "Correct. The Declaratory Act was passed following colonial resistance to the Stamp Act, which Britain had implemented to help pay for debts from the Seven Years’ War.",
    "Incorrect. The Declaration of Independence was drafted a decade later, in 1776, and was not a factor in the 1766 Declaratory Act.",
    "Incorrect. Although tensions with Native Americans existed, they were not the main factor behind this particular legislation, which focused on asserting British authority over the colonies."
  ]
}}
</EXAMPLE>

<EXAMPLE>
Input:
    Unit: Unit 4: Period 4: 1800–1848
    Topic: 4.3 Politics and Regional Interests

{{
  "stimulus": "“The Erie Canal poured into New York City [wealth] far exceeding that which its early friends predicted. . . . In the city, merchants, bankers, warehousemen, [and] shippers . . . seized the opportunity to perfect and specialize their services, fostering round after round of business innovations that within a decade of the opening of the Erie Canal had made New York by far the best place in America to engage in commerce. . . .\n“. . . Even before its economic benefits were realized fully, rival seaports with hopes of tapping interior trade began to imagine dreadful prospects of permanent eclipse. Whatever spirit of mutual good feeling and national welfare once greeted [internal improvements] now disappeared behind desperate efforts in cities . . . to create for themselves a westward connection.”\n\nJohn Lauritz Larson, historian, Internal Improvement: National Public Works and the Promise of Popular Government in the Early United States, 2001",
  "question": "Which of the following developments in the early nineteenth century could best be used as evidence to support the argument in the second paragraph of the excerpt?",
  "answers": [
    "The opposition of some political leaders to providing federal funds for public works",
    "The failure of some infrastructure projects to recover their costs",
    "The recruitment of immigrant laborers to work on new transportation projects",
    "The rise of a regional economy based on the production and export of cotton"
  ],
  "correct_answer": 0,
  "explanations": [
    "Correct. The excerpt discusses rival cities scrambling to create their own infrastructure projects in response to the Erie Canal’s success, which is reflected in political leaders' debates and opposition to federal funding for internal improvements.",
    "Incorrect. While relevant to infrastructure, this choice does not directly support the argument about cities reacting competitively to the Erie Canal’s success.",
    "Incorrect. Immigrant labor recruitment was significant but does not support the specific point about regional rivalry and infrastructure investment.",
    "Incorrect. The Southern cotton economy was an important development but unrelated to the competition among seaports to establish trade routes to the interior."
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
- The first question should present a realistic, AP-style stimulus (passage, scenario, table, or set of documents). The second question should not present a stimulus.
- Ask 3 related sub-questions that require students to:
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
    Unit: Unit 3: Period 3: 1754–1800
    Topic: 3.2 The Seven Years’ War (The French and Indian War)

Output:
{{
  "stimulus": "",
  "questions": [
    "Briefly describe one British government policy enacted in colonial North America from 1763 to 1776.",
    "Briefly explain one similarity OR difference in how TWO groups in North America responded to a British policy from 1763 to 1783.",
    "Briefly explain how one specific historical development contributed to the American colonists’ victory over Great Britain from 1775 to 1783."
  ],
  "rubric": [
    "Examples that earn this point include the following:\n• The British government enacted new taxes to raise revenue.\n• The British government collected taxes without colonial representation in Parliament.\n• The British government established the Proclamation Line to reduce tensions with Native Americans by preventing settlers from moving westward.\n• British officials blockaded American ports to assert imperial authority over the colonies.",
    "Examples that earn this point include the following:\n• While loyalists sought to remain loyal to the crown, Patriots argued that colonists should fight for their liberties.\n• Native Americans supported the Royal Proclamation of 1763 preventing colonial encroachment, while the colonists defied the Proclamation of 1763 moving west.\n• The Sons and Daughters of Liberty both protested policies through supporting boycotts on British imported goods.",
    "Examples that earn this point include the following:\n• Assistance from European allies helped the Patriots overcome the British advantage and win the war.\n• The actions of colonial militias helped overcome Great Britain's overwhelming military and financial advantage and contributed to the colonist victory over Great Britain.\n• Colonial women provided important material and financial support to the Patriot cause."
  ]
}}
</EXAMPLE>

<EXAMPLE>
Input:
    Unit: Unit 6: Period 6: 1865–1898
    Topic: 6.12 Controversies over the Role of Government in the Gilded Age
    
Output:
{{
  "stimulus": "[The Standard Oil Trust] is the most perfectly developed trust in existence. ... The perfection of the organization of [it], the ability and daring with which it has carried out its projects, make it the preeminent trust of the world. ... So long as the Standard Oil Company can control transportation as it does today, it will remain master of the oil industry. ...\n... The ethical cost of all this is the deep concern. We are a commercial people. . .. As a consequence, business success is sanctified, and, practically, any methods which achieve it are justified by a larger and larger class. All sorts of subterfuges ' and sophistries? and slurring over of facts are employed to explain aggregations of capital whose determining factor has been like that of the Standard Oil Company, special privileges obtained by persistent secret effort in opposition to the spirit of the law, the efforts of legislators, and the most outspoken public opinion.\nIda Tarbell, journalist, The History of the Standard Oil Company, 1904",
  "questions": [
    "Briefly describe one point of view suggested in the excerpt.",
    "Briefly explain how one specific historical development between 1865 and 1904 contributed to the development described in the excerpt.",
    "Briefly explain how ideas such as those reflected in the excerpt resulted in one specific effect between 1904 and 1920."
  ],
  "rubric": [
    "Examples that earn this point include the following:\n• The point of view of the excerpt is that of a reformer.\n• The point of view of the excerpt is that the Standard Oil Company is too big.\n• The author believes that government needs to step in to regulate large corporations.",
    "Examples that earn this point include the following:\n• The development of trusts like Standard Oil was partly a result of the popularity of laissez-faire policies that opposed government intervention in the economy.\n• The federal government supported policies that placed few restrictions on companies like Standard Oil, allowing it to become a trust.\n• Companies like Standard Oil eliminated their competition to create monopolies, which made them very powerful.\n• Policies that restricted the power of labor organizations contributed to companies like Standard Oil becoming more powerful.",
    "Examples that earn this point include the following:\n• The concerns raised by Tarbell contributed to calls by Progressives for federal legislation that they believed would effectively regulate the economy.\n• By publishing her ideas, Tarbell gained support from the public, which contributed to trust-busting by the government.\n• The criticisms of reforms about the power of corporations like Standard Oil resulted in the increased power of the federal government over the economy."
  ]
}}
</EXAMPLE>
"""
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
        mcq_gen(
            class_name=class_name,
            unit_name=unit_name,
            unit_id=unit_id,
            unit_number=unit_number,
        )


def main():
    process_class(14)


if __name__ == "__main__":
    main()
