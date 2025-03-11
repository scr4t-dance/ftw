import {createBrowserRouter, RouterProvider} from 'react-router-dom';

import HomePage from './components/HomePage';
import EventList from './components/EventList';

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
  ]);

const App = () => {
	return (
		<RouterProvider router={router} />
	);
}

export default App;