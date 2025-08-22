import {createBrowserRouter, RouterProvider} from 'react-router-dom';

import HomePage from './components/HomePage';
import EventList from './components/EventList';

import NewEventForm from './components/NewEventForm';
import Rules from './components/Rules';
import About from './components/About';

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
	  path: "/about",
	  element: <About />,
	},
	{
	  path: "/rules",
	  element: <Rules />,
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