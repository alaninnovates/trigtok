import os
import json
from platform import system

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
- Include a brief, relevant stimulus (such as a passage, diagram, experiment summary, or data table). Stimuli may use latex as necessary.
- Write a multiple-choice question that tests deeper conceptual understanding or reasoning, not simple recall
- Provide four answer choices with only one correct answer and three plausible distractors
- Mark the correct answer's index
- Provide a short explanation justifying the correct answer and eliminating the incorrect ones"""),
        types.Part.from_text(
            text=f"""<EXAMPLE>
Input:
    Unit: Unit 1: Renaissance and Exploration
    Topic: 1.1 Contextualizing Renaissance and Discovery

Output: {{"stimulus": "“Assume, O men of the German lands, that ancient spirit of yours with which you so often confounded and terrified the Romans and turn your eyes to the frontiers of Germany; collect her torn and broken territories. Let us be ashamed, ashamed I say, to have placed upon our nation the yoke of slavery. . . . O free and powerful people, O noble and valiant race. . . . To such an extent are we corrupted by Italian sensuality and by fierce cruelty in extracting filthy profit that it would have been far more holy and reverent for us to practice that rude and rustic life of old, living within the bounds of self-control, than to have imported the paraphernalia of sensuality and greed which are never sated, and to have adopted foreign customs.” - Conrad Celtis, oration delivered at the University of Ingolstadt, 1492", "question": "The passage above most clearly shows the influence of which of the following trends in fifteenth-century Europe?", "answers": ["The development of natural philosophy based on inductive and deductive reasoning", "The revival of classical learning and the development of Northern humanism", "The continued reliance on traditional supernatural explanations of the world", "The development of Baroque dramatic forms to enhance the stature of elites"], "correct_answer": 1, "explanations": ["Incorrect. The passage is a moral and nationalistic appeal drawing on historical and cultural critiques, not an argument focused on scientific methodology or the study of the natural world.", "Correct. Celtis explicitly references the \"Romans\" and appeals to an \"ancient spirit,\" demonstrating a revival of classical learning, while his critique of \"Italian sensuality\" and call for a return to perceived \"rude and rustic life of old\" reflect the moral and nationalistic concerns characteristic of Northern humanism.", "Incorrect. The passage emphasizes human agency, national identity, and moral choices, rather than attributing events or phenomena to supernatural causes or divine intervention.", "Incorrect. Baroque forms emerged much later than 1492 (the date of the oration), and the passage's content is a rhetorical appeal to the populace, not a description or example of dramatic art designed for elite display."]}}
</EXAMPLE>

<EXAMPLE>
Input:
    Unit: Unit 3: Absolutism and Constitutionalism
    Topic: 3.5 The Dutch Golden Age

Output: {{"stimulus": "“The Natives of New-Holland may appear to some to be the most wretched people upon Earth, but in reality they are far happier than we Europeans; being wholly unacquainted not only with the superfluous but the necessary Conveniencies so much sought after in Europe, they are happy in not knowing the use of them. They live in a Tranquility which is not disturbed by the Inequality of Condition: The Earth and sea of their own accord furnishes them with all things necessary for life, they covet not Magnificent Houses, Household-stuff, etc., they live in a warm and fine Climate and enjoy a very wholesome Air, so that they have very little need of Clothing. . . . Many to whom we gave Cloth left it carelessly upon the beach and in the woods as a thing they had no manner of use for. In short they seemed to set no Value upon any thing we gave them, nor would they ever part with any thing of their own for any one article we could offer them; this in my opinion argues that they think themselves provided with all the necessaries of Life and that they have no superfluities.” - James Cook, British naval officer, describing the inhabitants of Australia, 1770", "question": "Compared to Cook’s portrayal of the inhabitants of Australia in the late eighteenth century, the predominant European view of non-European peoples in the late nineteenth century had changed in which of the following ways?", "answers": ["Europeans in the late nineteenth century tended to view less structured and hierarchical societies as more desirable political models.", "Europeans in the late nineteenth century tended to view lack of technological development as evidence of cultural inferiority.", "Europeans in the late nineteenth century tended to view economically undeveloped societies as fairer and more just.", "Europeans in the late nineteenth century tended to view climate as less significant than other factors in determining social development."], "correct_answer": 1, "explanations": ["Incorrect. In the late nineteenth century, Europeans were actively imposing their own highly structured and hierarchical political systems (colonialism) on non-European societies, viewing their own models as superior, not less structured ones.", "Correct. The late nineteenth century saw the rise of Social Darwinism and imperialism, which often justified European dominance by viewing non-European peoples' lack of European-style technological development as proof of their inherent cultural or racial inferiority.", "Incorrect. By the late nineteenth century, European powers largely viewed their own economically developed societies as superior and more just, often justifying the exploitation of "undeveloped" societies as a civilizing mission or a means to acquire resources.", "Incorrect. While climate was still considered, the late nineteenth-century emphasis shifted more towards theories of racial superiority and technological advancement, rather than primarily climate, as the main drivers of social development, thereby still viewing non-European societies as less developed."]}}
</EXAMPLE>

<EXAMPLE>
Input:
    Unit: Unit 4: Scientific, Philosophical, and Political Developments
    Topic: 4.3 The Enlightenment

Output: {{"stimulus": "“The foundations of old knowledge have collapsed. Wise men have probed the depths of the earth; Treasures of buried strata furnish the proofs of creation. [Religion] is no longer the apex of fulfillment for the intelligent. Atlas does not hold up the earth, nor is Aphrodite divine; Plato’s wisdom cannot explain the principles of evolution. ‘Amr is no slave of Zayd, nor is Zayd ‘Amr’s master *— Law depends upon the principle of equality. Neither the fame of Arabia, nor the glory of Cairo remains. This is the time for progress; the world is a world of science; Is it possible to maintain society in ignorance?” - Sâdullah Pasha, Ottoman intellectual, The Nineteenth Century, poem, 1878", "question": "By the 1920s and 1930s, the ideas concerning science and progress reflected in the poem underwent which of the following transformations?", "answers": ["The ideas were largely rejected by non-Western leaders as incompatible with indigenous norms and cultures.", "The ideas were largely supplanted by a revival of religious sentiment in the wake of the First World War.", "The ideas came to be regarded with suspicion by many European intellectuals in the light of subsequent scientific discoveries and political events.", "The ideas were regarded with increasing hostility by European intellectuals in the wake of growing anticolonial movements in Asia and Africa."], "correct_answer": 2, "explanations": ["Incorrect. The period saw continued efforts by non-Western leaders to adopt and integrate Western science and technology for modernization, rather than largely rejecting it as incompatible.", "Incorrect. While there might have been individual instances, the predominant intellectual trend among many European intellectuals after WWI was a questioning of science and progress, not a widespread supplanting of these ideas by a religious revival.", "Correct. The unprecedented destruction of World War I, coupled with revolutionary scientific discoveries (like relativity and quantum mechanics) and the rise of totalitarian regimes, led many European intellectuals to view the optimistic 19th-century ideas about science and progress with suspicion.", "Incorrect. While anticolonial movements were significant, the primary reasons for European intellectual suspicion towards science and progress stemmed more directly from internal European events like the World Wars, new scientific paradigms, and totalitarianism, rather than from anticolonial movements themselves."]}}
</EXAMPLE>
""")
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


def generate_frqs(class_name: str, unit_name: str, topic: str) -> list[FreeResponseQuestion]:
    system_instructions = [
        types.Part.from_text(
            text=f"""You are a test writer for the {class_name} Exam.

Your task is to write 2 realistic Free Response Questions (FRQ) for the provided topic and unit.

Follow these guidelines:
- The first question should present a realistic, AP-style stimulus (experiment description, scenario, passage, table, or set of documents). Stimuli may use latex as necessary. The second question should not present a stimulus.
- Ask 3-4 related sub-questions that require students to:
    - Analyze, interpret, or explain key concepts from the topic
    - Apply reasoning or make predictions
    - Use appropriate evidence or data
- Format it clearly and professionally, as it would appear on the AP Exam
- Include a scoring rubric or brief explanation of how each part would be evaluated (what earns credit)
Use the tone, depth, and expectations of real AP FRQs. Ensure the task demands align with the AP’s cognitive rigor.
- Avoid overly simplistic or vague questions that do not require higher-order thinking"""),
        types.Part.from_text(
            text=f"""<EXAMPLE>
Input:
    Unit: Unit 4: Scientific, Philosophical, and Political Developments
    Topic: 4.2 The Scientific Revolution

Output: {{"stimulus": "“In the exhilarating period between the years 1600 and 1700, . . . empirical inquiry evolved from the freewheeling, speculative frenzy [of previous centuries] into something with powers of discovery on a wholly new level. . . . [This was] a regimented process that subjected theories to a pitiless interrogation by observable evidence, raising up some and tearing down others, occasionally changing course or traveling in reverse but making in the long term unmistakable progress. [The new method] permitted nothing but matters of explanatory power, nothing but a theory’s ability to account for the observable, to determine the course of scientific argument. Theology, philosophy, even beauty [became] strictly off limits. Scientists, if they chose to dispute, were obliged to do so in the empirical manner.” Source: Michael Strevens, The Knowledge Machine, 2020", "questions": ["Describe an argument made in the excerpt.", "Explain how one piece of historical evidence not in the excerpt would support an argument about science made in the excerpt.", "Explain one way in which the change discussed in the excerpt affected European society in the period 1600 to 1800."], "rubric": ["Examples that earn this point include the following:\n• During the Scientific Revolution, scientific inquiry became more regimented and disciplined.\n• Scientists began to use only empirical evidence to argue for their theories.\n• Doing science became a process of eliminating bad ideas on the basis of evidence.\n• Scientists narrowed their focus to observable evidence and how well such evidence explained natural phenomena.", "Examples that earn this point include the following:\n• Galileo’s observations with a telescope were used to discredit the geocentric model of the solar system and promote heliocentrism and/or Kepler’s laws of planetary motion.\n• Harvey’s observations of the actions of the heart were used to undermine the theory of humors and establish more accurate notions of anatomy.\n• Newton’s mathematical models of force, acceleration, and gravity were used to explain the motion of physical objects and displacing earlier models of mechanics.\n• Boyle’s work developed the field of chemistry, separating it from alchemy.\n• Bacon’s scientific methodology required a hypothesis to be tested with rigorous experimentation and observation.", "Examples that earn this point include the following:\n• The Enlightenment evolved as an intellectual outgrowth of the Scientific Revolution examining human society using scientific practices of natural observation and empiricism.\n• The success of the empirical approach within the sciences encouraged intellectuals to try this approach, or at least adopt the language of empiricism, in their attempts to improve society and government.\n• Scientific discoveries gradually began to lead to technological improvements in many areas, such as medicine.\n• The prestige of science and scientific discoveries led monarchs and governments to support scientific inquiry by funding and patronage of scientific societies."]}}
</EXAMPLE>

<EXAMPLE>
Input:
    Unit: Unit 1: Renaissance and Exploration
    Topic: 1.6 Technological Advances and the Age of Exploration

Output: {{"stimulus": "", "questions": ["Describe one similarity between Portuguese and Spanish overseas expansion in the period 1450 to 1650.", "Describe one difference between Portuguese and Spanish overseas expansion in the period 1450 to 1650.", "Explain one reason why the rise of new colonial powers such as England, France, and the Dutch Republic led to conflicts in the 1600s and 1700s."], "rubric": ["Examples that earn this point include the following:\n• Both countries sought overseas sources of valuable luxury goods, such as gold and spices.\n• Both countries made use of advances in military and maritime technology to support their exploration and conquest.\n• Both countries’ colonization efforts were centrally directed under control of the monarchy.\n• Both countries used systemic forms of violence to establish and maintain their power overseas.","Examples that earn this point include the following:\n• Spain became a great power in Europe, while Portugal did not become a great European power.\n• Portugal’s empire was mainly in Africa, India, and East Asia; Spain’s empire was mostly in the Americas.\n• Portugal’s empire consisted mostly of coastal enclaves and trading posts; Spain conquered large areas of the interior of the Americas and established expansive colonies.","Examples that earn this point include the following:\n• Religious divisions between Catholic and Protestant countries in Europe started to spill over into conflicts in their respective overseas colonies.\n• The desire for access to luxury goods from overseas lands led to competition between the various European states.\n• The wars of Louis XIV resulted in a coalition of powers assembling against him, and this conflict spilled into the colonies.\n• Britain and the Netherlands took over large parts of Asia that had previously been under Portuguese control."]}}
</EXAMPLE>""")
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


def process_class(class_id: int):
    class_data = next((c for c in classes_data if c["id"] == class_id), None)
    class_name = class_data["name"]
    for unit in filter(lambda u: u["class_id"] == class_id, units_data):
        unit_id = unit["id"]
        unit_name = unit["name"]
        unit_number = unit["number"]
        print(f"Generating MCQs for {class_name} - {unit_number} {unit_name}")
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
                file = f"generated_new/{class_name}_frqs_{unit_number}_{topic["topic"]}.json"
                os.makedirs(os.path.dirname(file), exist_ok=True)
                with open(file, "w") as f:
                    json.dump([q.model_dump() for q in mcq_response], f, indent=2)
                should_retry = False


def main():
    process_class(8)


if __name__ == "__main__":
    main()
