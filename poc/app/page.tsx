import { findTeams } from '../src/teams';
import { formatDates, upcomingRaces, type Race } from '../src/races';

const heading = "Where's my";

type SearchParams = Promise<{ team_ds?: string }>;

export default async function HomePage({ searchParams }: { searchParams: SearchParams }) {
  const { team_ds: teamDs } = await searchParams;
  const teams = await findTeams(teamDs);
  const races: Record<string, Race[]> = Object.fromEntries(await Promise.all(
    [...new Set(teams.map((team) => team.teamType))].map(async (teamType) => [teamType, await upcomingRaces(teamType)]),
  ));

  return (
    <main>
      <h1>
        {heading}{' '}
        <a href="https://www.reddit.com/r/PodiumCafe2/">Podium Cafe v2</a>
      </h1>
      <form method="get">
        <label htmlFor="team_ds">DS name or team name:</label>
        <input id="team_ds" name="team_ds" defaultValue={teamDs} />
        <button type="submit">Search</button>
      </form>
      {teams.map((team) => (
        <div className={`results ${team.teamType}`} key={`${team.teamType}-${team.ds}-${team.name}`}>
          <h2>{team.name} - {team.ds}</h2>
          {races[team.teamType]?.map((race) => (
            <div className="race" key={race.pcsName}>
              <h3>
                <a href={`https://cyclingflash.com/race/${race.pcsName}-${new Date().getUTCFullYear()}/startlist`}>{race.name}</a>
                <span className="date">{formatDates(race)}</span>
              </h3>
            </div>
          ))}
        </div>
      ))}
      {teamDs?.trim() && teams.length === 0 ? <div className="no-teams"><h2>No teams found!</h2></div> : null}
    </main>
  );
}
