# Your first contribution

New to GitHub? Start here. You'll add your name to [CONTRIBUTORS.md](../CONTRIBUTORS.md) and open your first pull request. It takes about ten minutes, and you can do it all in the browser: no Git, no terminal, nothing to install.

You'll learn the steps every open source contribution follows: **fork, branch, change, commit, pull request, review, merge.**

## What you need

- A free [GitHub account](https://github.com/signup).
- That's all.

## 1. Fork the repository

A fork is your own copy of the project on GitHub. You can change it freely without touching the original.

1. Open <https://github.com/A7medAmine/nebdaw-Cs>.
2. Click **Fork** (top right), then **Create fork**.

You now have `https://github.com/<your-username>/nebdaw-Cs`.

## 2. Edit CONTRIBUTORS.md in your fork

1. In **your fork**, click the file `CONTRIBUTORS.md`.
2. Click the pencil icon (**Edit this file**).
3. Under `## People`, add one line with your name. Keep the list in alphabetical order by GitHub username:

   ```
   - [Your Name](https://github.com/your-username) - CS student at <your university>
   ```

   Use your real GitHub username in the link, and keep the line short. Don't change other people's lines.

4. Click **Preview** to check that your name shows up as a link.

## 3. Commit your change

1. Click **Commit changes...**
2. Commit message: `docs: add <your-name> to contributors`
3. Choose **Create a new branch for this commit and start a pull request**. Name the branch something like `add-your-name`.
4. Click **Propose changes**.

Working on a branch instead of `main` is a good habit: it keeps each change separate.

## 4. Open the pull request

A pull request (PR) asks the maintainer to take your change into the original project.

1. GitHub now shows **Open a pull request**. Check that it goes from `<your-username>/nebdaw-Cs` (your branch) into `A7medAmine/nebdaw-Cs` (`main`).
2. Title: `docs: add <your-name> to contributors`.
3. In the description, write one line, for example "My first contribution!". The checklist is about the setup scripts; you can leave it empty for this change.
4. Click **Create pull request**.

## 5. Wait for review

The maintainer will look at your PR. They may:

- **Merge it.** Your name is now in the project. Congratulations!
- **Ask for a change.** Go back to your branch in your fork, edit `CONTRIBUTORS.md` again and commit to the same branch. The PR updates by itself.

Automatic checks (CI) may run on your PR. For a first-time contributor they wait until the maintainer approves them; that's normal.

### "This branch has conflicts"

If several people add their names at the same time, GitHub may say your branch has conflicts. Click **Resolve conflicts**, keep everyone's lines (yours and theirs), delete the lines with `<<<<<<<`, `=======` and `>>>>>>>`, then click **Mark as resolved** and **Commit merge**. Or ask the maintainer to fix it for you.

## Prefer the terminal?

If you have Git installed, you can do the same from your PC:

```sh
git clone https://github.com/<your-username>/nebdaw-Cs.git
cd nebdaw-Cs
git checkout -b add-your-name
# edit CONTRIBUTORS.md
git add CONTRIBUTORS.md
git commit -m "docs: add <your-name> to contributors"
git push -u origin add-your-name
```

Then open your fork on GitHub and click **Compare & pull request**.

## What next?

Now that you know the steps, try a real change:

- Run the setup on your PC and [report how it went](https://github.com/A7medAmine/nebdaw-Cs/issues/new/choose).
- Pick an issue labelled [`good first issue`](https://github.com/A7medAmine/nebdaw-Cs/labels/good%20first%20issue).
- Read the [contributing guide](../CONTRIBUTING.md) for the rules on the setup scripts and the VS Code profile.
