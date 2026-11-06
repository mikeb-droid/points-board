# Peyton's Points Board

A family points app that runs on any phone, tablet or computer. Everyone signs in with their own email and password. Peyton checks off tasks; only a parent login can approve them, give bonus points, or change tasks and prizes. Changes show up on everyone's screen within a second or two.

Free to run: Supabase (database + logins) and Vercel (hosting) both have free tiers that cover a family app easily.

---

## 1. Create the database (about 10 minutes)

1. Go to **supabase.com**, sign up, and click **New project**. Name it `points-board`, pick a database password (save it somewhere; you won't need it day to day), choose the US East region, and create it. Wait a minute or two while it sets up.
2. In the left sidebar open **SQL Editor** → **New query**. Open `setup.sql` from this folder, copy everything, paste it in, and click **Run**. You should see "Success. No rows returned."
3. Turn off public sign-ups so strangers can't make accounts: **Authentication** → **Sign In / Providers** (or **Settings**) → turn **Allow new users to sign up** OFF → Save.
4. Get your two keys: **Project Settings** → **API** (sometimes labeled **Data API** / **API Keys**). Copy the **Project URL** and the **anon public** key. Open `config.js` in this folder and paste them in place of the placeholders.

## 2. Add the family logins

1. **Authentication** → **Users** → **Add user** → **Create new user**. Enter an email and password, and tick **Auto Confirm User**. Do this for:
   - you
   - Peyton's mom (or any other parent)
   - Peyton (any email works, even one she doesn't check; she just needs to type it once on her device)
2. Open **SQL Editor** → **New query**, paste in `add-family.sql`, replace the three placeholder emails and names, and click **Run**. The table at the bottom should list all three people with the right roles.

To add someone later, repeat both steps for that person. To remove someone, delete them under **Authentication** → **Users**.

## 3. Put it online with Vercel (about 5 minutes)

Easiest path, through GitHub in the browser:

1. On **github.com**, click **New repository**, name it `points-board`, set it to **Private**, and create it.
2. On the new repo page, click **uploading an existing file**, drag in every file from this folder (after editing `config.js`), and click **Commit changes**.
3. On **vercel.com**, click **Add New** → **Project**, import `points-board`, leave every setting as is, and click **Deploy**.
4. Vercel gives you a link like `points-board-xyz.vercel.app`. That's the app. You can rename it under the project's **Settings** → **Domains**.

To change the app later, upload the changed file to GitHub again; Vercel redeploys on its own.

## 4. Put it on everyone's home screen

Open the link on each phone and sign in. Then:
- **iPhone/iPad (Safari):** Share button → **Add to Home Screen**.
- **Android (Chrome):** ⋮ menu → **Add to Home screen** / **Install app**.

It opens full screen like a normal app and stays signed in.

---

## How the points work

- Peyton taps the box when a task is done. It shows **Waiting for a parent** until a parent approves it. Only approved tasks count.
- Parents see two extra tabs: **Approve** (everything waiting, plus bonus or deduction points) and **Setup** (tasks, prizes, name).
- Every approved point counts toward every prize at once:
  - **This week** prizes count Monday to Sunday and reset each Monday.
  - **This month** prizes count the calendar month.
  - **Big goal** prizes count from a start date you pick, with an optional deadline.
- When a prize is unlocked, a parent taps **Mark as given** so everyone knows it's been handed over.
- Removing a task or prize hides it but keeps any points already earned.

The starter tasks and prizes (homework 10 pts on school days, reading 5, bed 2, dishes 4, backpack 3, room 10 on Saturdays; prizes at 100 / 400 / 1,200) are only a starting point. A perfect week with that list is about 150 points. Change them in **Setup**.

## Safety notes

- The **anon public** key in `config.js` is meant to be visible. The data is protected by sign-in plus database rules in `setup.sql`: only family members on the list can see anything, and only parent logins can approve or edit. Peyton's login is blocked from approving at the database level, not only hidden in the app.
- Keep sign-ups turned off (step 1.3).
- Never put the **service_role** key anywhere in this folder.

## Files

| File | What it is |
|---|---|
| `index.html` | The app |
| `config.js` | Your Supabase URL and anon key |
| `setup.sql` | Run once to create the database |
| `add-family.sql` | Run to add parent and kid logins |
| `manifest.json`, `icon*` | Home-screen app icon |
