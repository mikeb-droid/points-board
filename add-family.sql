-- Run this AFTER creating each person under Authentication > Users > Add user.
-- Change the emails and names to match, then Run. Run it again any time you add someone.

insert into members (user_id, role, name)
select id, 'parent', 'Mike' from auth.users where email = 'PARENT-ONE-EMAIL@example.com'
on conflict (user_id) do update set role = excluded.role, name = excluded.name;

insert into members (user_id, role, name)
select id, 'parent', 'Mom' from auth.users where email = 'PARENT-TWO-EMAIL@example.com'
on conflict (user_id) do update set role = excluded.role, name = excluded.name;

insert into members (user_id, role, name)
select id, 'kid', 'Peyton' from auth.users where email = 'PEYTON-EMAIL@example.com'
on conflict (user_id) do update set role = excluded.role, name = excluded.name;

-- Check who's on the list:
select m.name, m.role, u.email from members m join auth.users u on u.id = m.user_id;
