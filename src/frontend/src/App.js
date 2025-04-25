import { createBrowserRouter, RouterProvider } from 'react-router';

import HomePage from './components/HomePage';
import EventList from './components/EventList';

import NewEventForm from './components/NewEventForm';
import About from './components/About';
import React from 'react';
import EventPage from './components/EventPage';
import NewCompetitionFormPage from './components/NewCompetitionFormPage';
import CompetitionPage from './components/CompetitionPage';
import DancerList from './components/DancerList';
import NewDancerForm from './components/NewDancerForm';
import DancerPage from './components/DancerPage';

const router = createBrowserRouter([
	{
		path: "/",
		element: <HomePage />,
	},
	{
		path: "index.html",
		element: <HomePage />,
	},
	{
		path: "/events",
		element: <EventList />,
	},
	{
		path: "/events/:id_event",
		element: <EventPage />,
	},
	{
		path: "/competitions/:id_competition",
		element: <CompetitionPage />,
	},
	{
		path: "/event",
		element: <NewEventForm />,
	},
	{
		path: "/dancer",
		element: <DancerList />,
	},
	{
		path: "/dancer/:id_dancer",
		element: <DancerPage />,
	},
	{
		path: "/dancer/new",
		element: <NewDancerForm />,
	},
	{
		path: "/about",
		element: <About />,
	},
	{
		path: "/new/event",
		element: <NewEventForm />,
	},
	{
		path:"/new/competition",
		element: <NewCompetitionFormPage />
	}
]);

const App = () => {
	return (
		<RouterProvider router={router} />
	);
}

export default App;