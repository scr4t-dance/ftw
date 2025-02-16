import React, { useEffect } from 'react';
import useEventApi from '../hooks/useEventApi'; 

const EventComponent = () => {
  const {
    data,
    error,
    loading,
    createEvent,
    getEventDetails,
    getEventComps,
    getAllEvents,
  } = useEventApi();

  useEffect(() => {
    getAllEvents(); // Fetch all events when the component mounts
  }, []);

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <div>
      <h1>Event Details</h1>
      {data && (
        <div>
          {data.map((event) => (
            <div key={event.id}>
              <h2>{event.name}</h2>
              <button onClick={() => getEventDetails(event.id)}>Get Details</button>
              <button onClick={() => getEventComps(event.id)}>Get Competitions</button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default EventComponent;
