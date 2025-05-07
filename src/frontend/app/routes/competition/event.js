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


  console.log(data);
  console.log(error);
  console.log(loading);
  
  console.log("finished getting all events");

  return (
    <div>
      <h1>Event Details</h1>
      {data && (
        <div> ok
          {data.events.map((event_id) => (
            <div>
            {event_id}
            </div>
          ))}

        </div>
      )}
    </div>
  );
};

export default EventComponent;
