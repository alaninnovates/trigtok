import json
import os
import dotenv
from supabase import create_client

dotenv.load_dotenv()

client = create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_SERVICE_ROLE_KEY"))

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

for file in os.listdir("ap_euro_mcqs"):
    split_dot = file.split(".")
    split = '.'.join(split_dot[:-1]).split("_")
    class_name = split[0]
    question_type = split[1]
    unit_number = int(split[2])
    topic_name = split[3]

    print(class_name, question_type, unit_number, topic_name)

    class_id = next(
        (c["id"] for c in classes_data if c["name"] == class_name), None
    )
    unit_id = next(
        (u["id"] for u in units_data if u["class_id"] == class_id and u["number"] == unit_number), None
    )
    topic_id = next(
        (t["id"] for t in topics_data if t["unit_id"] == unit_id and t["topic"].endswith(topic_name)), None
    )

    print(f"Class ID: {class_id}, Unit ID: {unit_id}, Topic ID: {topic_id}")
    data = json.loads(open("ap_euro_mcqs/" + file).read())
    insert_data = []
    for question in data:
        insert_data.append({
            "stimulus": question["stimulus"],
            "question": question["question"],
            "answers": question["answers"],
            "correct_answer": question["correct_answer"],
            "explanations": question["explanations"],
            "unit_id": unit_id,
            "topic": topic_id,
        })
    print(f"Inserting {len(insert_data)} questions for {class_name} unit {unit_number} topic {topic_name}")
    client.table("multiple_choice_questions").insert(insert_data).execute()