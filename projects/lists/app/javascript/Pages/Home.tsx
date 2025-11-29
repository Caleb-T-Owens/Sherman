import Layout from "@/components/Layout";

function Home() {
  return (
    <article>
      <h1>Welcome to Lists</h1>
      <small>Better name pending</small>
      <p>
        Lists is a very basic website that I built to be my browser's new-tab
        page. There are certain sites that I visit frequently but end up doing a
        search in order to reach. I wanted a way of pinning specific pages and
        visiting them via a fuzzy search.
      </p>
      <p>
        I am very aware that there are other services that do the same thing and
        this is not a unique idea - but I wanted to make my own... so I did.
      </p>
      <h2>The "My list" page</h2>
      <img
        src={"/images/your-sites.png"}
        style={{ maxWidth: "min(80vw, 600px)", border: "4px inset black" }}
        alt="The my list page filled with some example sites"
      />
      <p>
        The "My list" page is where all the exciting stuff happens. The main
        attraction is the text input that gets auto-focused. Typing in there
        fuzzy searches your list of sites. The site with the black border is
        focused by a cursor. Pressing <kbd>ctrl+enter</kbd> visits the site
        focused by the cursor. The cursor can be moved up and down with{" "}
        <kbd>ctrl+k</kbd> and <kbd>ctrl+j</kbd> respectivly.
      </p>
      <p>
        If you don't have a site added yet, you can use the "Search Google" and
        "Search Wikipedia" buttons to search those databases.
      </p>
      <h2>Adding a site</h2>
      <img
        src={"/images/add-a-site.png"}
        style={{ maxWidth: "min(80vw, 400px)", border: "4px inset black" }}
        alt="The add a site modal"
      />
      <p>
        When adding a site, you can paste in the URL and make use of the
        "Auto-fill" button to fetch that website's metadata and have the title &
        description auto-filled for you.
      </p>
      <h2>Hotkeys</h2>
      <table>
        <tr>
          <th>Keybind</th>
          <th>Scope</th>
          <th>Action</th>
        </tr>
        <tr>
          <td>ctrl + n</td>
          <td>Global</td>
          <td>Opens the new site modal</td>
        </tr>
        <tr>
          <td>ctrl + e</td>
          <td>Global</td>
          <td>
            Opens the edit site modal for the currently cursor-focused site
          </td>
        </tr>
        <tr>
          <td>ctrl + s</td>
          <td>New site modal | Edit site modal</td>
          <td>Saves the site</td>
        </tr>
        <tr>
          <td>ctrl + m</td>
          <td>New site modal | Edit site modal</td>
          <td>
            Fetches site <b>m</b>etadata
          </td>
        </tr>
        <tr>
          <td>ctrl + c</td>
          <td>New site modal | Edit site modal</td>
          <td>Closes the modal</td>
        </tr>
        <tr>
          <td>ctrl + k</td>
          <td>Global</td>
          <td>Moves the cursor up</td>
        </tr>
        <tr>
          <td>ctrl + j</td>
          <td>Global</td>
          <td>Moves the cursor down</td>
        </tr>
        <tr>
          <td>ctrl + enter</td>
          <td>Global</td>
          <td>Opens the current cursor-focused site</td>
        </tr>
        <tr>
          <td>ctrl + g</td>
          <td>Global</td>
          <td>Opens Google with the your current search term</td>
        </tr>
        <tr>
          <td>ctrl + w</td>
          <td>Global</td>
          <td>Opens Wikipedia with the your current search term</td>
        </tr>
      </table>
    </article>
  );
}

Home.layout = (page: React.ReactElement) => <Layout children={page} />;

export default Home;
