import { createBrowserRouter, RouterProvider } from 'react-router-dom';

import HomePage from './components/HomePage';
import EventList from './components/EventList';

import NewEventForm from './components/NewEventForm';
import About from './components/About';
import React from 'react';

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
		path: "/event",
		element: <NewEventForm />,
	},
	{
		path: "/about",
		element: <About />,
	},
	{
		path: "/new/event",
		element: <NewEventForm />,
	},
]);

const App = () => {
	return (
		<RouterProvider router={router} />
	);
}

export default App;