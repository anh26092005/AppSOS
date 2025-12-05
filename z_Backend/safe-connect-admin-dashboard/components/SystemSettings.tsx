import React, { useState, useEffect } from 'react';
import { systemSettingsService } from '../services/systemSettingsService';
import { userService } from '../services/userService';
import { SystemSettings as SystemSettingsType, User } from '../types';
import AvatarImage from './AvatarImage';

const SystemSettings: React.FC = () => {
  const [settings, setSettings] = useState<SystemSettingsType | null>(null);
  const [loading, setLoading] = useState(true);
  const [updating, setUpdating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // User list & search
  const [users, setUsers] = useState<User[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [loadingUsers, setLoadingUsers] = useState(false);

  // Load settings on mount
  useEffect(() => {
    fetchSettings();
  }, []);

  // Load users when search term changes or page changes
  useEffect(() => {
    fetchUsers();
  }, [searchTerm, currentPage]);

  const fetchSettings = async () => {
    try {
      setLoading(true);
      const data = await systemSettingsService.getSystemSettings();
      setSettings(data);
      setError(null);
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to load settings');
    } finally {
      setLoading(false);
    }
  };

  const fetchUsers = async () => {
    try {
      setLoadingUsers(true);
      const response = await userService.getUsers({
        page: currentPage,
        limit: 10,
        search: searchTerm || undefined,
      });
      setUsers(response.data);
      setTotalPages(response.pagination.pages);
    } catch (err: any) {
      console.error('Failed to load users:', err);
    } finally {
      setLoadingUsers(false);
    }
  };

  const handleDemoModeToggle = async () => {
    if (!settings) return;

    try {
      setUpdating(true);
      const newDemoMode = !settings.demoMode;
      const updatedSettings = await systemSettingsService.updateDemoMode(newDemoMode);
      setSettings(updatedSettings);
      setError(null);
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to update demo mode');
    } finally {
      setUpdating(false);
    }
  };

  const handleToggleDemoAccess = async (userId: string, currentAccess: boolean) => {
    try {
      await systemSettingsService.updateUserDemoAccess(userId, !currentAccess);
      // Refresh users list
      fetchUsers();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to update demo access');
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-400">Đang tải...</div>
      </div>
    );
  }

  return (
    <div className="p-6">
      <h1 className="text-3xl font-bold text-white mb-6">Cài đặt hệ thống</h1>

      {error && (
        <div className="bg-red-900/50 border border-red-700 text-red-200 px-4 py-3 rounded mb-6">
          {error}
        </div>
      )}

      {/* Demo Mode Toggle */}
      <div className="bg-gray-800 rounded-lg p-6 mb-6">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-xl font-semibold text-white mb-2">Demo Mode</h2>
            <p className="text-gray-400 text-sm">
              Khi bật, chỉ những tài khoản được cấp phép mới có thể sử dụng chức năng SOS
            </p>
          </div>
          <button
            onClick={handleDemoModeToggle}
            disabled={updating}
            className={`relative inline-flex h-8 w-14 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:ring-offset-gray-800 ${
              settings?.demoMode ? 'bg-blue-600' : 'bg-gray-600'
            } ${updating ? 'opacity-50 cursor-not-allowed' : ''}`}
          >
            <span
              className={`inline-block h-6 w-6 transform rounded-full bg-white transition-transform ${
                settings?.demoMode ? 'translate-x-7' : 'translate-x-1'
              }`}
            />
          </button>
        </div>
        {settings?.demoMode && (
          <div className="mt-4 bg-yellow-900/30 border border-yellow-700 text-yellow-200 px-4 py-3 rounded">
            <p className="text-sm">
              ⚠️ Demo mode đang BẬT. Chỉ users được cấp quyền mới có thể gọi SOS.
            </p>
          </div>
        )}
      </div>

      {/* User Management Section */}
      <div className="bg-gray-800 rounded-lg p-6">
        <h2 className="text-xl font-semibold text-white mb-4">Quản lý quyền Demo</h2>

        {/* Search Bar */}
        <div className="mb-4">
          <input
            type="text"
            placeholder="Tìm kiếm user theo tên, phone, email..."
            value={searchTerm}
            onChange={(e) => {
              setSearchTerm(e.target.value);
              setCurrentPage(1);
            }}
            className="w-full bg-gray-700 text-white px-4 py-2 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        {/* Users Table */}
        {loadingUsers ? (
          <div className="text-center text-gray-400 py-8">Đang tải...</div>
        ) : users.length === 0 ? (
          <div className="text-center text-gray-400 py-8">Không tìm thấy user nào</div>
        ) : (
          <>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-700">
                    <th className="text-left py-3 px-4 text-gray-400 font-medium">User</th>
                    <th className="text-left py-3 px-4 text-gray-400 font-medium">Liên hệ</th>
                    <th className="text-left py-3 px-4 text-gray-400 font-medium">Vai trò</th>
                    <th className="text-center py-3 px-4 text-gray-400 font-medium">Demo Access</th>
                  </tr>
                </thead>
                <tbody>
                  {users.map((user) => (
                    <tr key={user._id || user.id} className="border-b border-gray-700/50 hover:bg-gray-700/30">
                      <td className="py-3 px-4">
                        <div className="flex items-center">
                          <AvatarImage src={user.avatar} alt={user.name} size="sm" />
                          <span className="ml-3 text-white">{user.name}</span>
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        <div className="text-gray-300 text-sm">
                          <div>{user.phone}</div>
                          {user.email && <div className="text-gray-500">{user.email}</div>}
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        <div className="flex gap-1">
                          {user.roles?.map((role) => (
                            <span
                              key={role}
                              className="px-2 py-1 text-xs rounded-full bg-blue-900/50 text-blue-200"
                            >
                              {role}
                            </span>
                          ))}
                        </div>
                      </td>
                      <td className="py-3 px-4 text-center">
                        <button
                          onClick={() => handleToggleDemoAccess(user._id || user.id, (user as any).isDemoAllowed || false)}
                          className={`px-4 py-1.5 rounded text-sm font-medium transition-colors ${
                            (user as any).isDemoAllowed
                              ? 'bg-green-600 text-white hover:bg-green-700'
                              : 'bg-gray-600 text-gray-300 hover:bg-gray-500'
                          }`}
                        >
                          {(user as any).isDemoAllowed ? 'Có quyền' : 'Không quyền'}
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Pagination */}
            {totalPages > 1 && (
              <div className="mt-4 flex justify-center gap-2">
                <button
                  onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                  disabled={currentPage === 1}
                  className="px-3 py-1 bg-gray-700 text-white rounded disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-600"
                >
                  ← Trước
                </button>
                <span className="px-3 py-1 text-gray-400">
                  Trang {currentPage} / {totalPages}
                </span>
                <button
                  onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
                  disabled={currentPage === totalPages}
                  className="px-3 py-1 bg-gray-700 text-white rounded disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-600"
                >
                  Sau →
                </button>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
};

export default SystemSettings;
