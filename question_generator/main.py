import os
import json
from google import genai
from google.genai import types
import dotenv
from pydantic import BaseModel

dotenv.load_dotenv()

client = genai.Client(
        api_key=os.environ.get("GEMINI_API_KEY"),
    )
model = "gemini-2.0-flash"

"""
[
  {
    "id": #,
    "name": ""
  }
]
"""
classes_data = json.loads(open("data/classes.json").read())
"""
[
  {
    "id": #,
    "class_id": #,
    "name": "",
    "next_unit": #,
    "number": #
  },
]
"""
units_data = json.loads(open("data/units.json").read())
"""
[
  {
    "id": #,
    "unit_id": #,
    "topic": "",
    "next_topic": #
  },
]
"""
topics_data = json.loads(open("data/topics.json").read())


class MultipleChoiceQuestion(BaseModel):
    stimulus: str
    question: str
    answers: list[str]
    correct_answer: int
    explanations: list[str]
    topic: str
    unit: int


def generate_mcqs(
    class_name: str,
    unit_name: str,
    topics: list[str],
    quantity: int,
    history_mode: bool,
    math_mode: bool,
) -> list[MultipleChoiceQuestion]:
    contents = [
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(
                    text=f"""Generate {quantity} Multiple Choice Questions for the class {class_name}, based on the topics and selected unit in the most recent Course and Exam Description, provided below.
For each topic within a unit, have some questions provide a{history_mode and " historical text-based" or ""} stimulus.{math_mode and " Use Latex as necessary. Use tables as necessary." or ""}
Each Multiple Choice Questions should include 4 answers. For each answer, provide an explanation for why it is correct or incorrect. When generating answers, do not include a prefix.
Include the correct answer field as an index of which position within the answers array is correct.
Include the topic and unit that this multiple choice question is relevant to.

List of {class_name} Topics for Unit {unit_name}:
{'\n'.join(topics)}
"""
                )
            ],
        ),
    ]
    generate_content_config = types.GenerateContentConfig(
        response_mime_type="application/json",
        response_schema=list[MultipleChoiceQuestion]
    )

    response = client.models.generate_content(
        model=model,
        contents=contents,
        config=generate_content_config,
    )
    return response.parsed

class FreeResponseQuestion(BaseModel):
    stimulus: str
    questions: list[str]
    rubric: list[str]
    unit: int

def generate_frqs() -> list[FreeResponseQuestion]:
    contents = [
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(
                    text="""Generate 100 Free Response Questions for the class AP European History, based on the topics in the most recent CED. For each topic, have some questions provide a historical text-based stimulus. For each question, provide a rubric for grading a response. When generating questions, use the prefixes a), b), and c). When generating a rubric, start each with "Award 1 point for"
Do not use any racist or inappropriate ideas.
"""),
            ],
        ),
    ]
    generate_content_config = types.GenerateContentConfig(
        response_mime_type="application/json",
        response_schema=list[FreeResponseQuestion]
    )

    response = client.models.generate_content(
        model=model,
        contents=contents,
        config=generate_content_config,
    )
    return response.parsed


def process_class(class_id: int):
    class_data = next((c for c in classes_data if c["id"] == class_id), None)
    class_name = class_data["name"]
    for unit in filter(lambda u: u["class_id"] == class_id, units_data):
        unit_id = unit["id"]
        unit_name = unit["name"]
        unit_number = unit["number"]
        topics = [
            topic["topic"]
            for topic in filter(lambda t: t["unit_id"] == unit_id, topics_data)
        ]
        should_retry = True
        while should_retry:
            mcq_response = generate_mcqs(
                class_name=class_name,
                unit_name=f"Unit {unit_number}: {unit_name}",
                topics=topics,
                quantity=len(topics)*3,
                history_mode=True,
                math_mode=False,
            )
            print(f"Generated MCQs for {class_name} - {unit_number} {unit_name}")
            print(f"Topics: {topics}")
            if not mcq_response:
                print("No MCQs generated, retrying...")
                continue
            file = f"generated/{class_name}_mcqs_{unit_number}.json"
            os.makedirs(os.path.dirname(file), exist_ok=True)
            with open(file, "w") as f:
                json.dump([q.model_dump() for q in mcq_response], f, indent=2)
            should_retry = False

def main():
    process_class(14)


if __name__ == "__main__":
    main()
