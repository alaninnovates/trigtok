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
    # stimulus: str
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
    Unit: Unit 6: Cities and Urban Land-Use Patterns and Processes
    Topic: 6.10 Challenges of Urban Changes
Output: {{"question": "Which of the following factors best explains the development and expansion of squatter settlements?", "answers": ["Gentrification of megacities in more developed countries displacing large numbers of urban dwellers", "Rapid urbanization and inability of infrastructure to keep pace with the growth of megacities in developing countries", "Urban dwellers seeking residential housing and shopping outside the congestion of the city", "Zoning laws in developing countries that prevent current urban dwellers from obtaining land to build residential structures", "The growth of urban agriculture encouraging migrant farm workers to move to cities requiring more housing"], "correct_answer": 1, "explanations": ["Incorrect. Gentrification displaces residents but typically leads to higher-income housing, not the development of squatter settlements, which are characterized by informal, often improvised housing.", "Correct. Rapid urbanization in developing countries often outpaces the development of formal housing and infrastructure, leading to a shortage of affordable options and the spontaneous growth of squatter settlements.", "Incorrect. This describes suburbanization, where people move to the periphery for better housing and less congestion, a different phenomenon than the development of squatter settlements.", "Incorrect. While zoning laws can be restrictive, the primary driver of squatter settlements is the lack of affordable, formal housing options for a rapidly growing urban population, rather than solely preventing land acquisition.", "Incorrect. While urban agriculture can exist in squatter settlements, it is not the primary factor explaining their development and expansion; rather, the lack of formal housing options drives their growth."]}}
</EXAMPLE>

<EXAMPLE>
Input:
    Unit: Unit 1: Thinking Geographically
    Topic: 1.5 Human–Environmental Interaction

Output: {{"question": "The lush golf courses in the United Arab Emirates, the dikes and polders in the Netherlands, and the Three Gorges Dam in China are significant examples of land use. Which of the following viewpoints of human-environment interaction are best described by these land-use examples?", "answers": ["Environmental determinism", "Ecotourism", "Possibilism", "Heartland theory", "Malthusian theory"], "correct_answer": 2, "explanations": ["Incorrect. Environmental determinism suggests that the environment dictates human culture and development, while these examples show humans actively modifying their environment.", "Incorrect. Ecotourism focuses on responsible travel to natural areas, which is not the primary characteristic of large-scale land modifications like golf courses, dikes, or dams.", "Correct. Possibilism is the viewpoint that humans have the ability to adapt and modify their environment to suit their needs and desires, as demonstrated by these extensive land-use projects.", "Incorrect. Heartland theory is a geopolitical concept about land power, unrelated to human-environment interaction or specific land-use examples.", "Incorrect. Malthusian theory deals with population growth outstripping resource availability, which is not directly illustrated by these examples of environmental modification."]}}
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
- Ask 7 related sub-questions that require students to:
    - Analyze, interpret, or explain key concepts from the topic
    - Apply reasoning or make predictions
    - Use appropriate evidence or data
- Format it clearly and professionally, as it would appear on the AP Exam
- Include a scoring rubric or brief explanation of how each part would be evaluated (what earns credit)
- Use the tone, depth, and expectations of real AP FRQs. Ensure the task demands align with the AP's cognitive rigor.
- Avoid overly simplistic or vague questions that do not require higher-order thinking"""
        ),
        types.Part.from_text(
            text=f"""<EXAMPLE>
Input:
    Unit: Unit 4: Political Patterns and Processes
    Topic: 4.1 Introduction to Political Geography

Output: {{"stimulus": "In most countries, the concept of the state as a political unit is subject to the tensions between centrifugal and centripetal forces. Governments are often challenged by the devolutionary factors that challenge state sovereignty.", "questions": ["Define the concept of the multinational state.", "Explain how ethnicity can be a factor that leads to the devolution of a state.", "Explain how communication technology plays an important role in the goals of devolutionary groups and democracy movements.", "Explain the limitations of communication technology in furthering the goals of devolutionary groups and democracy movements.", "Describe ONE centripetal force that governments use to promote the state as a nation.", "Explain how uneven development within a state can act as a centrifugal force.", "For a multinational state facing the realities of devolution, explain why a government would choose to create an autonomous region or choose to maintain a unitary state."]], "rubric": ["• A country with multiple culture groups or multiple ethnic groups under a single government.", "Accept one of the following:\n• Ethnic differences, ethnocentrism, or ethnic separatism can be the source of conflict between culture groups, or between one ethnic group and a government.\n• One or more ethnic groups may control a government, while another ethnic group has limited political power.\n• Ethnic nationalist political parties may compete for political power or attempt to gain control of territory.\n• An ethnic group existing within a territory shared with other culture groups may attempt to gain control through armed conflict, ethnic cleansing, or terrorism", "Accept one of the following:\n• Personal computers, personal communication devices, or cell phones can be used to connect people who support a common ethnic, religious, or political desire to devolve the state or reform the government.\n• Software applications (apps) for social networking can be used to connect people who support a common ethnic, religious, or political desire to devolve the state or reform the government.\n• Radio. television, news, or the internet can be used to broadcast ethnic, religious, or political groups intent to devolve the state or reform the government.", "Accept one of the following:\n• Governments can shut down cellular phone towers, data networks, or satellite uplinks to prevent social networking\n• Governments can filter or block information entering their country via the Internet or on social network sites.\n• Governments can ban media from broadcasting information, news, websites or other media regarding an ethnic, religious, or political groups who intend to devolve the state or reform the government.\n• Governments can counter devolutionary groups and democracy movements with pro-government applications, information, news or media.", "Accept one of the following:\n• When a part of a country is neglected economically by a government, resentful local residents may attempt to gain local or regional political control.\n• Countries with primate cities can have a highly-developed city or capital while the rest of the country is relatively underdeveloped; this can create devolutionary pressures.", "Accept one of the following:\n• The creation of an autonomous region would give an ethnic group limited self-determination, but this may weaken the state’s control over the region’s territory, people, and resources.\n• Maintaining a unitary state would give the government full control over territory, people, and resources, but this risks rebellion against the state by the region’s ethnic group."]}}
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
                        "stimulus": "",
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
    process_class(9)


if __name__ == "__main__":
    main()
