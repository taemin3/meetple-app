import '../../models/auth_session.dart';
import '../../models/auth_user.dart';

const mockAuthUser = AuthUser(
  id: 1,
  nickname: '김모임',
  handle: 'gather_together',
  email: 'meetple@example.com',
  createdMeetingsCount: 12,
  joinedMeetingsCount: 28,
  likedMeetingsCount: 15,
);

const mockAuthSession = AuthSession(
  user: mockAuthUser,
  accessToken: 'mock-access-token',
  refreshToken: 'mock-refresh-token',
);
