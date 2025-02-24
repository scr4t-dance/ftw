import {BrowserRouter as Router, Routes, Route} from 'react-router-dom';

import Accueil from './components/Accueil';
import EventList from './components/EventList';

const App = () => {
	return (
		<Router>
			<Routes>
				<Route path="/" element={<Accueil />}/>
				<Route path="/events" element={<EventList />}/>
			</Routes>
		</Router>
	);
}

export default App;