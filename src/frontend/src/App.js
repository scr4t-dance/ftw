import { BrowserRouter, Routes, Route } from 'react-router';

import HomePage from './components/HomePage';
import EventList from './components/EventList';

import NewEventForm from './components/NewEventForm';
import About from './components/About';
import React from 'react';
import EventPage from './components/EventPage';
import NewCompetitionFormPage from './components/NewCompetitionFormPage';
import CompetitionPage from './components/CompetitionPage';

const App = () => {
	return (
		<BrowserRouter>
			<Routes>
				<Route index element={<HomePage />} />
				<Route path='index.html' element={<HomePage />} />
				<Route path='events'>
					<Route index element={<EventList />} />
					<Route path='new' element={<NewEventForm />} />
					<Route path=':id_event' element={<EventPage />} />
				</Route>
				<Route path='about' element={<About />} />
			</Routes>
		</BrowserRouter>
	);
}

export default App;