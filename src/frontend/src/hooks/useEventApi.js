import { useState } from 'react';

const BASE_URL = 'https://localhost:8080/api';

const useEventApi = () => {
	const [data, setData] = useState(null);
	const [error, setError] = useState(null);
	const [loading, setLoading] = useState(false);

	// A generic fetch function to handle GET, PUT requests
	const fetchData = async (url, method = 'GET', body = null) => {
		setLoading(true);
		setError(null);

		const options = {
			method,
			headers: {
				'Content-Type': 'application/json',
			},
			body: body ? JSON.stringify(body) : null,
		};

		try {
			const response = await fetch(url, options);
			const result = await response.json();

			if (!response.ok) {
				throw new Error(result.message || 'Something went wrong');
			}

			setData(result);
		} catch (error) {
			setError(error.message);
		} finally {
			setLoading(false);
		}
	};

	// Event API calls
	const createEvent = (eventData) => {
		fetchData(`${BASE_URL}/event`, 'PUT', eventData);
	};

	const getEventDetails = (id) => {
		fetchData(`${BASE_URL}/event/${id}`);
	};

	const getEventComps = (id) => {
		fetchData(`${BASE_URL}/event/${id}/comps`);
	};

	const getAllEvents = () => {
		fetchData(`${BASE_URL}/events`);
	};

	return {
		data,
		error,
		loading,
		createEvent,
		getEventDetails,
		getEventComps,
		getAllEvents,
	};
};

export default useEventApi;
