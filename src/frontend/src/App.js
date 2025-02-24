import {BrowserRouter as Router, Routes, Route} from 'react-router-dom';

import HomePage from './components/HomePage';
import EventList from './components/EventList';

const App = () => {
	return (
		<Router>
			<Routes>
				<Route path="/" element={<HomePage />}/>
				<Route path="/events" element={<EventList />}/>
			</Routes>
		</Router>
	);
}

export default App;