# Bridge

Bridge is an open-source project for building comprehensive, free language courses created by AI and the community. 

## Project Overview

Bridge is a platform where you'll be able to find language courses created through AI and refined by teachers from all around the world. It aims to offer a sort of dynamic "Wikipedia" for language learning, where you'll be able to find lessons on all the relevant grammar when learning a language, complete vocabulary lists, audiovisual resources, exercises, tutors and more.

The motivation behind this is pretty clear: language apps are ineffective and overly gamified, seeming more like games than courses; language courses are generic and don't offer language-specific capabilities, and despite there being a lot of content online there is no clear repository where one may find an organized and ready-to-learn version of it. Seizing the fact that AI has learned from sources that teach languages, we can generate an initial course draft using AI that should be quite accurate; but since it will 100% miss things, miscategorize lessons, misplace words or just commit errors, we will refine these courses with the help of teachers.

## Getting started

If you have docker installed, you can just run `make up` to start the Elixir/Phoenix app and the Postgres container. If not, make sure you have a Postgres instance running on port 4000 and run `mix phx.server`.

## Documentation Structure

For now, documentation will be stored in the issues, but we will create a Wiki soon with all the information about the project's structure, API routes and such. This will come when we start creating feature PRs.

## Contribution Guidelines

Since this is my first open-source project, I will refine the contribution system as time goes. If you're interested in helping on the early stages, contact me and I'll loop you into everything we're doing. Any help is appreciated!

## Technical Details

As of now, the app is simply an Elixir app with a Phoenix frontend and a Postgres database.

The app is deployed on `fly.io`, with the database being hosted in `Supabase`.

