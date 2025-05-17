import { BrowserRouter, Routes, Route } from 'react-router';

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
import CompetitionList from './components/CompetitionList';

const App = () => {
	return (
		<BrowserRouter>
			<Routes>
				<Route index element={<HomePage />} />
				<Route path='index.html' element={<HomePage />} />
				<Route path='competitions'>
					<Route index element={<CompetitionList />} />
					<Route path='new' element={<NewCompetitionFormPage />} />
					<Route path=':id_competition' element={<CompetitionPage />} />
				</Route>
				<Route path='events'>
					<Route index element={<EventList />} />
					<Route path='new' element={<NewEventForm />} />
					<Route path=':id_event' element={<EventPage />} />
				</Route>
				<Route path='dancer'>
					<Route index element={<DancerList />} />
					<Route path='new' element={<NewDancerForm />} />
					<Route path=':id_event' element={<DancerPage />} />
				</Route>
				<Route path='about' element={<About />} />
			</Routes>
		</BrowserRouter>
	);
}

export default App;