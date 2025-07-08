import os
import json
import math
import asyncio
import aiohttp
from typing import List, Dict, Optional, Union
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class GoogleMapsClient:
    """
    Google Maps API client for fetching distance matrix and route information.
    Falls back to mock data if API key is not configured.
    """

    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or os.getenv('GOOGLE_MAPS_API_KEY')
        self.base_url = "https://maps.googleapis.com/maps/api"
        self.session: Optional[aiohttp.ClientSession] = None

        # Traffic multipliers based on time of day
        self.traffic_multipliers = {
            "peak": 1.8,      # 8-10 AM, 5-7 PM
            "moderate": 1.3,  # 10 AM - 5 PM
            "low": 1.0        # 7 PM - 8 AM
        }

        # Base speeds for different vehicle types (km/h)
        self.vehicle_speeds = {
            "motorcycle": 25,
            "van": 20,
            "truck": 15
        }

    def is_configured(self) -> bool:
        """Check if Google Maps API key is set"""
        return bool(self.api_key)

    async def get_session(self) -> aiohttp.ClientSession:
        """Get or create an aiohttp session."""
        if self.session is None or self.session.closed:
            self.session = aiohttp.ClientSession()
        return self.session

    async def close_session(self):
        """Close the aiohttp session."""
        if self.session:
            await self.session.close()
            self.session = None

    def calculate_haversine_distance(self, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculate Haversine distance between two points in kilometers."""
        R = 6371  # Earth radius km
        phi1, phi2 = math.radians(lat1), math.radians(lat2)
        dphi = math.radians(lat2 - lat1)
        dlambda = math.radians(lon2 - lon1)
        a = math.sin(dphi/2)**2 + math.cos(phi1)*math.cos(phi2)*math.sin(dlambda/2)**2
        return R * (2 * math.atan2(math.sqrt(a), math.sqrt(1-a)))

    def get_traffic_multiplier(self, current_time: Optional[datetime] = None) -> float:
        """Return traffic multiplier based on time of day."""
        now = current_time or datetime.now()
        h = now.hour
        if (8 <= h < 10) or (17 <= h < 19):
            return self.traffic_multipliers['peak']
        elif 10 <= h < 17:
            return self.traffic_multipliers['moderate']
        else:
            return self.traffic_multipliers['low']

    def estimate_duration_from_distance(self, distance_km: float, vehicle_type: str = 'van', consider_traffic: bool = True) -> int:
        """Estimate travel time (minutes) from distance and traffic."""
        speed = self.vehicle_speeds.get(vehicle_type, 20)
        base_minutes = (distance_km / speed) * 60
        if consider_traffic:
            multiplier = self.get_traffic_multiplier()
            base_minutes *= multiplier
        return int(base_minutes)

    async def get_distance_matrix_from_api(self, origins: List[str], destinations: List[str], consider_traffic: bool = True) -> Optional[Dict]:
        """Fetch distance matrix from Google Maps API."""
        if not self.is_configured():
            return None
        session = await self.get_session()
        params = {
            'origins': '|'.join(origins),
            'destinations': '|'.join(destinations),
            'key': self.api_key,
            'units': 'metric',
            'mode': 'driving'
        }
        if consider_traffic:
            params['departure_time'] = 'now'
            params['traffic_model'] = 'best_guess'
        url = f"{self.base_url}/distancematrix/json"
        try:
            async with session.get(url, params=params) as resp:
                data = await resp.json()
                if resp.status == 200 and data.get('status') == 'OK':
                    return data
                else:
                    logger.error(f"Distance Matrix API error: {data.get('status')}")
        except Exception as e:
            logger.error(f"Error calling Distance Matrix API: {e}")
        return None

    def generate_mock_distance_matrix(self, points: List[Dict], consider_traffic: bool = True) -> Dict[str, Dict[str, Dict]]:
        """Generate mock matrix via Haversine and traffic heuristics."""
        matrix: Dict[str, Dict[str, Dict]] = {}
        for i, p1 in enumerate(points):
            id1 = p1.get('id', str(i))
            matrix[id1] = {}
            for j, p2 in enumerate(points):
                id2 = p2.get('id', str(j))
                if id1 == id2:
                    matrix[id1][id2] = {'distance_km': 0.0, 'duration_minutes': 0, 'traffic_delay_minutes': 0}
                else:
                    dist = self.calculate_haversine_distance(p1['lat'], p1['lon'], p2['lat'], p2['lon'])
                    dur = self.estimate_duration_from_distance(dist, consider_traffic=consider_traffic)
                    no_traffic = self.estimate_duration_from_distance(dist, consider_traffic=False)
                    delay = dur - no_traffic
                    matrix[id1][id2] = {
                        'distance_km': round(dist, 2),
                        'duration_minutes': dur,
                        'traffic_delay_minutes': int(delay)
                    }
        return matrix

    async def get_distance_matrix(self, points: List[Union[Dict, object]], consider_traffic: bool = True) -> Dict[str, Dict[str, Dict]]:
        """Return full distance matrix, API or mock fallback."""
        # Normalize points to dicts
        flat: List[Dict] = []
        for item in points:
            if hasattr(item, 'lat') and hasattr(item, 'lon'):
                flat.append({
                    'id': getattr(item, 'id', None) or '',
                    'lat': getattr(item, 'lat', None),
                    'lon': getattr(item, 'lon', None)
                })
            else:
                flat.append(item)
        ids = [p.get('id', str(i)) for i, p in enumerate(flat)]
        coords = [f"{p['lat']},{p['lon']}" for p in flat]
        # Try API
        api_data = await self.get_distance_matrix_from_api(coords, coords, consider_traffic)
        if api_data and 'rows' in api_data:
            matrix: Dict[str, Dict[str, Dict]] = {}
            for i, origin in enumerate(api_data['origin_addresses']):
                oid = ids[i]
                matrix[oid] = {}
                for j, dest in enumerate(api_data['destination_addresses']):
                    element = api_data['rows'][i]['elements'][j]
                    if element.get('status') == 'OK':
                        dist_m = element['distance']['value']
                        dur_s = element['duration']['value']
                        dur_traffic = element.get('duration_in_traffic', {}).get('value', dur_s)
                        matrix[oid][ids[j]] = {
                            'distance_km': round(dist_m/1000, 2),
                            'duration_minutes': int(dur_s/60),
                            'traffic_delay_minutes': int((dur_traffic - dur_s)/60)
                        }
                    else:
                        matrix[oid][ids[j]] = {'distance_km': 0.0, 'duration_minutes': 0, 'traffic_delay_minutes': 0}
            return matrix
        # Fallback mock
        logger.info('Using mock distance matrix')
        return self.generate_mock_distance_matrix(flat, consider_traffic)

# Example usage
if __name__ == '__main__':
    import asyncio
    # Load sample mock data
    sample = []
    try:
        with open(os.path.join('data', 'mock_deliveries.json')) as f:
            j = json.load(f)
            if 'sample_locations' in j:
                sample = j['sample_locations']
    except FileNotFoundError:
        pass

    async def test():
        client = GoogleMapsClient()
        matrix = await client.get_distance_matrix(sample)
        print(json.dumps(matrix, indent=2))
        await client.close_session()

    asyncio.run(test())
