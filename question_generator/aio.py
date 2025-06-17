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
    Unit: Unit 1: The Global Tapestry
    Topic: 1.1 Developments in East Asia from c. 1200 to c. 1450

Output: {{"stimulus": "“The ruler is a boat; people are the water. The water can carry the boat; the water can capsize the boat. . . . A man may be the descendant of kings, lords, or nobles, but if he does not observe the norms of ritual and proper behavior he must be relegated to the status of a commoner. Similarly, he may be a descendant of commoners, but if he accumulates learning of the texts, corrects his behavior, and observes the norms of ritual and proper behavior-then he must be elevated to the ranks of high ministers, lords, and nobles.” - Xunzi, Chinese philosopher, circa 250 b.c.e.", "question": "Xunzi’s idealized vision of Chinese society in the passage differs most strongly from the social structure of which of the following?", "answers": ["Roman society during the late empire", "Hindu society in South Asia during the Gupta Empire", "Muslim society during the early Caliphates", "Mongol society during the period of Mongol conquests"], "correct_answer": 1, "explanations": ["Incorrect. Although Roman society was hierarchical, individuals could still rise in status through military service or administrative roles, which aligns in part with Xunzi’s belief in merit-based advancement.", "Correct. The Hindu caste system was a rigid, birth-based social structure that directly contradicted Xunzi’s vision of social mobility through moral conduct and education.", "Incorrect. Despite social divisions, early Islamic societies often emphasized merit and learning, particularly in religious and bureaucratic contexts, which is consistent with the values expressed by Xunzi.", "Incorrect. Mongol rulers frequently promoted individuals based on military skill and loyalty rather than noble birth, which aligns with the meritocratic ideals advocated by Xunzi."]}}
</EXAMPLE>

<EXAMPLE>
Input:
    Unit: Unit 6: Consequences of Industrialization
    Topic: 6.3 Indigenous Responses to State Expansion from 1750 to 1900

Output: {{"stimulus": ""Poem 1: “The world calls us coolie.*\nWhy doesn’t our flag fly anywhere?\nHow shall we survive, are we slaves forever?\nWhy aren’t we involved in politics?\nFrom the beginning we have been oppressed.\nWhy don’t we even dream of freedom?\nOnly a handful of oppressors have taken our fields.\nWhy has no Indian cultivator risen and protected his land?\nOur children cry out for want of education.\nWhy don’t we open science colleges?”\n*An insulting term for South or East Asian manual workers.\nPoem 2: “Why do you sit silent in your own country\nYou who make so much noise in foreign lands?\nNoise outside of India is of little avail.\nPay attention to activities within India.\nYou are quarreling and Hindu-Muslim conflict is prevalent.\nThe jewel of India is rotting in the earth\nbecause you are fighting over the Vedas and the Koran.\nGo and speak with soldiers.\nAsk them why they are asleep, men who once held swords.\nMuslim, Hindu, and Sikh heroes should join together.\nThe power of the oppressors is nothing if we unitedly attack him.\nIndians have been the victors in the battlefields\nof Burma, Egypt, China and the Sudan.”", "question": "In Poem 1, the sentiments regarding education and politics are best understood in the context of which of the following?", "answers": ["The persistence of slavery in spite of the abolitionist movement in the British Empire.", "The growth of women’s movements pushing for greater education and domestic rights.", "The British failure to provide mass education in India, for fear that doing so would encourage resistance against imperial rule.", "The revival of traditional Hindu and Muslim religious beliefs in India"], "correct_answer": 2, "explanations": ["Incorrect. The poem addresses political oppression and lack of education in colonial India, not the institution of slavery or its abolition.", "Incorrect. The poem focuses broadly on colonial oppression and education barriers affecting Indian cultivators, without specific reference to gender or women’s movements.", "Correct. The poem’s emphasis on children lacking education and the call to “open science colleges” reflects the colonial policy of restricting Indian education to limit nationalist resistance.", "Incorrect. The poem critiques oppression and political exclusion but does not advocate or mention religious revival as a cause or solution."]}}
</EXAMPLE>

<EXAMPLE>
Input:
    Unit: Unit 5: Revolutions
    Topic: 5.4 Industrialization Spreads in the Period from 1750 to 1900

Output: {{"stimulus": "“I can safely say that before the commencement of what I may call the Railway Period, not only were the wages in most parts of the country established by tradition and authority, rather than by the natural laws of supply and demand, but the opportunity to work was in general restricted to particular spots. For the first time in history the Indian finds that he has in his power of labor a valuable possession which, if he uses it right, will give him something much better than mere subsistence. Follow him to his own home, in some remote village, and you will find that the railway laborer has brought back not only new modes of working and a new feeling of self-respect and independence, but also new ideas of what government and laws can offer him. And he is, I believe, a better and more loyal subject, as he is certainly a more useful laborer.” - Bartle Frere, British governor of the Bombay Presidency, India, speech on opening of a rail line, 1863", "question": "Frere’s view of the changing opportunities for Indian labor most directly reflects the influence of which of the following?", "answers": ["The ideals of classical liberalism as stated by Adam Smith and John Stuart Mill.", "The ideals of communism as stated by Karl Marx and Friedrich Engels.", "The ideals of the Enlightenment as stated by political revolutionaries such as Simon Bolívar.", "The ideals of mercantilism as developed by European state-sponsored joint-stock trading"], "correct_answer": 0, "explanations": ["Correct. Frere’s emphasis on individual labor as a valuable asset reflects classical liberal beliefs in free markets, personal advancement, and supply and demand.", "Incorrect. Communism critiques capitalism, while Frere is praising capitalist labor systems under British rule.", "Incorrect. Bolívar and other revolutionaries focused on political independence, not economic opportunity under imperialism.", "Incorrect. Mercantilism emphasized state control of trade, not individual labor freedom or market-driven opportunities."]}}
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
            text=f"""<EXAMPLE>
Input:
    Unit: Unit 4: Transoceanic Interconnections
    Topic: 4.5 Maritime Empires Maintained and Developed

Output: {{"stimulus": "", "questions": ["Identify ONE method Europeans used to expand their empires in the Americas in the period circa 1450–1750.", "Explain ONE way European colonialism affected Indigenous peoples in the Americas in the period circa 1450–1750.", "Explain ONE way European interactions with non-European peoples in the Americas contributed to the development of a global economy in the period circa 1450–1750."], "rubric": ["Examples that earn this point include the following:\n• Europeans used gunpowder weapons to conquer new territories in the Americas.\n• The Spanish used the encomienda system to expand the areas in their empires under cultivation.\n• Europeans used Christianity to help consolidate and justify their rule.", "Examples that earn this point include the following:\n• Indigenous communities experienced multiple waves of diseases, epidemics, or even demographic collapse.\n• Many Indigenous peoples adopted European and/or African cultural practices that formed new syncretic belief systems.\n• European colonial authorities used priests and missionaries to convert Indigenous people to Christianity.\n• The casta system resulted in a new social hierarchy involving Indigenous and mixed race families.\n• Many Indigenous people were enslaved or forced to work in mines or on European owned haciendas.", "Examples that earn this point include the following:\n• European interactions with Indigenous peoples in the Americas led to the Columbian Exchange, which led to the spread of crops, technologies, goods, and diseases between the two hemispheres.\n• The Trans-Atlantic slave trade brought millions of enslaved Africans to the Americas and significantly expanded the Atlantic economy through plantations and cash crops.\n• Silver mined in the Americas using Indigenous labor fueled the purchase of Asian goods by Europeans, especially after the establishment of trans-Pacific maritime trade from the Americas to East Asia.\n• Economic exchanges in the North Atlantic, including the fur trade and commercial fishing, also connected the Americas to Afro-Eurasia in new ways."]}}
</EXAMPLE>

<EXAMPLE>
Input:
    Unit: Unit 3: Land-Based Empires
    Topic: 3.2 Empires: Administration

Output: {{"stimulus": "“Under the Mughals, Hindus and Muslims interacted in economics, politics, social life, the arts, and culture. Through migration and conversion, the Muslim population of India grew from about 400,000 in 1200, . . . to 12.8 million in 1535, to perhaps 50 million by 1800. Muslim scholars and Sufi religious mystics and saints migrated to India from Iran, Turkey, and Central Asia. Some came in search of government jobs, others for new cultural opportunities, to study, or to spread their own beliefs. Some of the best poets immigrated from Persia. Similarly, imperial court painters, who produced masterpieces in the Persian and Mughal miniature styles, interacted with painters of the Rajput schools in local Hindu courts across north India, resulting in artistic innovations in both. On the level of mystical belief and experience, an astonishing syncretism emerged between Hindus and Muslims, especially in the poetry of Kabir [died circa 1520] and of Guru Nanak (1469–1538), the originator of the Sikh religion. Mystics in the two communities, Hindu bhakti (devotional) worshippers and Muslim Sufis, frequently had warm personal relations and often attracted followers from each others’ communities.” Howard Spodek and Michele Langford Louro, United States historians, article published in a scholarly journal, 2007", "questions": ["Identify ONE claim that the authors make in the first paragraph.", "Identify ONE piece of evidence that the authors use to support their claims about cultural interactions between Hindus and Muslims as described in the second paragraph.", "Explain ONE reason why Mughal rulers in the period circa 1450–1750 would have encouraged the interactions described in the passage."], "rubric": ["Examples that earn this point include the following:\n• Hindus and Muslims interacted in many different ways, including economics, politics, social life, the arts, and culture.\n• The Muslim population of India grew substantially between 1200 and 1800.\n• Muslim scholars and Sufis migrated to India from Iran, Turkey, and Central Asia.\n• Some of the best poets migrated from Persia to India.","Examples that earn this point include the following:\n• Interactions between imperial court painters and Rajput painters resulted in artistic innovations.\n• The poetry of Kabir and Nanak contributed to Hindu, Muslim, and Sikh cultural syncretism.\n• Interactions between Muslim and Hindu mystics attracted followers from other religious communities.","Examples that earn this point include the following:\n• Mughal rulers wanted to keep their non-Muslim subjects from rebelling.\n• Mughal rulers believed that encouraging close relations between Muslims and nonMuslims would likely lead Hindus to accept Mughal rule.\n• Mughal rulers believed that encouraging close relations between Muslims and nonMuslims could help expand Mughal power by utilizing the economic, political, and military contributions of their full population."]}}
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
        mcq_gen(
            class_name=class_name,
            unit_name=unit_name,
            unit_id=unit_id,
            unit_number=unit_number,
        )


def main():
    process_class(15)


if __name__ == "__main__":
    main()
