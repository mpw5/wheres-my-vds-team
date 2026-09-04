import { findTeams, matchingRiders } from '../src/teams';
import { fetchStartlist, formatDates, prefetchUpcomingStartlists, upcomingRaces, type Race } from '../src/races';

const heading = "Where's my";
if (process.env.POC_DISABLE_STARTUP_PREFETCH !== 'true' && process.env.NEXT_PHASE !== 'phase-production-build') {
  void prefetchUpcomingStartlists();
}

type SearchParams = Promise<{ team_ds?: string }>;

export default async function HomePage({ searchParams }: { searchParams: SearchParams }) {
  const { team_ds: teamDs } = await searchParams;
  const teams = await findTeams(teamDs);
  const races: Record<string, Race[]> = Object.fromEntries(await Promise.all(
    [...new Set(teams.map((team) => team.teamType))].map(async (teamType) => [teamType, await upcomingRaces(teamType)]),
  ));
  const raceRiders = await Promise.all(teams.flatMap((team) => (races[team.teamType] ?? []).map(async (race) => [
    `${team.teamType}-${team.ds}-${team.name}-${race.pcsName}`,
    matchingRiders(team, await fetchStartlist(race)),
  ] as const)));
  const ridersByRace = Object.fromEntries(raceRiders);
  const teamTypes = [...new Set(teams.map((team) => team.teamType))];

  return (
    <main>
      <h1>
        {heading}{' '}
        <a href="https://www.reddit.com/r/PodiumCafe2/">Podium Cafe v2</a>
      </h1>
      <div className="search">
        <form method="get">
          <label htmlFor="team_ds">DS name or team name:</label>
          <input id="team_ds" name="team_ds" defaultValue={teamDs} />
          <button type="submit">Search</button>
        </form>
      </div>
      {teamTypes.map((teamType) => (
        <div className={`results ${teamType}`} key={teamType}>
          {teams.filter((team) => team.teamType === teamType).map((team) => <h2 key={`${teamType}-${team.ds}-${team.name}`}>{team.name} - {team.ds}</h2>)}
          {races[teamType]?.map((race, raceIndex) => {
            const startingRiders = teams
              .filter((team) => team.teamType === teamType)
              .flatMap((team) => ridersByRace[`${team.teamType}-${team.ds}-${team.name}-${race.pcsName}`] ?? [])
              .filter((rider, index, riders) => riders.indexOf(rider) === index);
            const raceKey = `${teamType}-${race.pcsName}-${race.startDate.toISOString()}-${raceIndex}`;
            return (
            <div className="race" key={raceKey} data-race-key={raceKey}>
              <h3>
                <a href={`https://cyclingflash.com/race/${race.pcsName}-${new Date().getUTCFullYear()}/startlist`}>{race.name}</a>
                <span className="date">{formatDates(race)}</span>
              </h3>
              {startingRiders.length > 0 ? <div className="riders-found">{startingRiders.map((rider) => rider.replace(/\b\w/g, (letter) => letter.toUpperCase())).join(', ')}</div> : <div className="no-riders">No riders found</div>}
            </div>
            );
          })}
        </div>
      ))}
      {teamDs?.trim() && teams.length === 0 ? <div className="no-teams"><h2>No teams found!</h2></div> : null}
    </main>
  );
}
