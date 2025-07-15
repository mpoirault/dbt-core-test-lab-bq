# Analytics Engineer Meetup assignment

Note that sharing this assignment is *not allowed*, this assignment is *not* in the public domain.

## Context: meetup.com

[Meetup.com](http://www.meetup.com) is a popular online platform with the aim of bringing together people with a shared interest in real-life events (Meetups). The Meetup community is composed of groups, where each group has a particular interest and organises events.

Users of meetup.com can become member of one or more groups. Whenever a group organises an event, members of that group have the opportunity to RSVP for an event (yes, we're using RSVP as a verb here). The RSVP for an event can be either a Yes or No answer, meaning respectively that the member is either planning to attend the event or is not. Not RSVP-ing to an event can be interpreted as a No.

Additionally, groups express the interests that they ostensibly have in terms of a number of topics (e.g. the [Spiritual Psychology Meetup](http://www.meetup.com/Spiritual-Psychology-Meetup/) has listed as topics: Philosophy, Self Exploration, Transformation, Meditation, etc.).

In summary, the essential entities and relations in the meetup.com ecosystem are:

- Users can join groups (becoming members)
- Groups have an organiser
- Groups discuss a set of topics
- Groups organise events
- Members can RSVP to events (Yes or No)
- An event is hosted at a venue

Apart from these basics, both groups, users, members, events and venues have particular metadata. You'll want to do some exploration of your own.

A special case of Meetup events is what we call tech meetups. These are events focusing on technology (usually Information Technology / software engineering / computer science), with a typical conference style setup, where there are presentations and the members that attend are audience. Tech meetups are generally organized with the goal of knowledge sharing within the professional IT community. However, since these events are often attended by individuals with relevant and sometimes scarce skills in what are considered cutting edge technologies, these events are also popular targets for sponsorships from organization who are actively hiring software engineers or data scientists (see [here](https://xebia.com/blog/the-dutch-data-meetup-ecosystem/) for some reference about the meetups that Xebia Data itself is involved in).

This Meetup assignment consists of two parts: an engineering assignment and an analytics assignment.

## Part 1: Build a simple data warehouse

The goal of the analytics engineering assignment is to take the data that is provided in the `data` folder, load it into some simple data warehouse to make it query-able, and connect it a tool for visualising and drilling down into the data.

We want to see that you are capable of contributing to data analytics, end-to-end.

### Suggested approach

For achieving this goal we would like you to:

1. Set up a simple data warehouse:
    - What tool you use is up to you, as long as it is different from the vizualisation tool.
    - Where it runs is also up to you, you can go local or to the cloud.
    - The data should be securely query-able via a well-known language such as SQL.
2. Build data pipelines that load the data:
    - Again, what tool you use and where it runs is up to you.
    - The pipelines themselves should be version controlled and should be able easily executable (e.g. via scheduling).
    - Consider implementing things like data testing and reconciliation and a simple data catalog.
    - Setting up things like CI/CD for your data pipelines is considered a bonus!
3. Set up the analytics and visualisation tool:
    - Set up your interactive visualisation tool of choice.
    - Connect to the simple data warehouse and show that you can query the data.
 
### The data

You have received data for all Meetup groups in the technology category within an area spanning a large part of The Netherlands, Belgium and some part of Germany (roughly all groups within a 100-mile radius from Amsterdam). The data contains information on groups, users, group membership, events and event RSVPs, this should all be load into your data warehouse.

Data is delivered in a number of separate files containing a single JSON blob of encoded arrays. See the `data_description.md` file for an extended description of the data.

## Part 2: Use analytics to inform the business

After demo-ing your data warehouse solution, including some awesome visualisations, to meetup.com, they get back to us with the following request:

> *We were impressed with the demo Xebia Data gave. We are considering providing Meetup organizers with a new service that provides useful insights into RSVP behaviour. Can you show us what insights might be interesting to provide in this service? And help us further shape the value proposition to end-user of the Meetup platform?*

For the second part of the assignment we ask you to help meetup.com with their request. Use the setup you built in part 1 of the assignment for doing your analysis and getting the insights.

Please consider for in your advice for meetup.com:
  - What insights are useful or useless? And which could be at the core of this new service? 
  - Can you outline the value proposition the insights provide to the end-users?
  - Can you already outline the potential business case for meetup.com?
  - Feel free to add other data sources besides the one that were provided with assignment.

The final result should be a presentation to be given to the Chief of Product and her team that is supported by interactive visualisations, allowing for drill down during the presentation based on questions of the audience present.

## Final evaluation

The evaluation will be done with two members of the Xebia Data team and consists of two parts:

1. The presentation of the advice you give to the Chief of Product at meetup.com, regarding the new service they want to develop. (1 hour)
2. A walkthrough and discussion of the solution build for part 1 and supporting part 2. (1 hour)

The goal of the presentation is to assess your skills in the following areas:

- Communication and presentation
- Creativity and innovation
- Problem-solving and strategic planning

Your technical solution should show that you understand the fundamentals of doing analytics engineering:

- Data storage 
- Data transformation
- Analytics and visualisation

Your solution will not be compared or scored to any existing solution. We care about your reasoning behind your work; we understand that developing a full-fledged advice and analytics setup will take substantial time. So please make sure that you do not get stuck in premature optimization.

We care about your ability to create data driven solutions that are useful for end users. In the end we are about creating sustainable solutions for our clients that will help them improve their organisation in the short and longer term. The result should fit that description.

The evaluation of your solution is based on a presentation given by you for two members of our team and on the solution itself.

> [!TIP]
> We have designed this assessment to allow candidates to demonstrate their strengths in many of the skills that relate to Analytics Engineering. As such, while we expect your evaluation to touch on many of the areas that form Analytics Engineering, we do not expect candidates to provide detailed solutions for all possible aspects of this assessment. What we do expect is an assessment that touches on the areas where you can bring most value. For example:
> * If you are candidate who excels in data visualisation, please show that you can implement engineering processes such as CI/CD pipelines or data quality tests, but feel free to focus on the visualisation aspect of your evaluation.
> * If you are a candidate with experience of design docs or architecture reviews, please show that you can write a robust data pipeline, but feel free to also provide a design doc or a rollout plan as part of your evaluation.

Please share your presentation and engineering solution with us beforehand, at least 12 hours in advance of your interview. Please send it in by mailing to [assessment.data.eu@xebia.com](mailto:assessment.data.eu@xebia.com).

## Questions

In case of questions or uncertainty you can send e-mail to [assessment.data.eu@xebia.com](mailto:assessment.data.eu@xebia.com).
